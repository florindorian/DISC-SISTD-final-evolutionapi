// api-backend/index.js (VERSÃO ATUALIZADA)

require('dotenv').config({ path: './.env.api' });

const express = require('express');
const { MongoClient, ObjectId } = require('mongodb'); // Adicionado 'ObjectId'
const bodyParser = require('body-parser'); // Adicionado body-parser

// 2. Configurações da API
const app = express();
const port = process.env.PORT || 3001;

// MIDDLEWARE: Habilita o Express a ler JSON no corpo das requisições POST
app.use(bodyParser.json());

// 3. Configurações do MongoDB
const uri = process.env.MONGO_CONNECTION_STRING;
const dbName = process.env.MONGO_DB_NAME;
const collectionName = process.env.MONGO_COLLECTION_NAME;

// 4. Conexão com o MongoDB (Código de conexão mantido)
let client;
const connectDB = async () => {
  try {
    // ... (Código de conexão)
    client = new MongoClient(uri);
    await client.connect();
    console.log('🚀 Conexão com MongoDB estabelecida com sucesso!');
  } catch (error) {
    console.error('❌ Erro ao conectar ao MongoDB:', error.message);
  }
};

connectDB();

// Middleware para garantir conexão ativa (mantido)
app.use(async (req, res, next) => {
    // ... (Código do middleware)
    if (!client || !client.topology.isConnected()) {
        console.warn('Tentativa de conexão durante a requisição...');
        await connectDB();
        if (!client || !client.topology.isConnected()) {
            return res.status(503).json({ 
                error: 'Serviço indisponível',
                message: 'A conexão com o banco de dados falhou ou está indisponível.' 
            });
        }
    }
    next();
});

// =========================================================================
// ROTA 1: Filtragem por Data (GET /ciclos) - Mantida
// =========================================================================
app.get('/ciclos', async (req, res) => {
  try {
    const db = client.db(dbName);
    const collection = db.collection(collectionName);
    
    // Pega a data da query string, ou usa a data/hora atual
    const dateQuery = req.query.date ? new Date(req.query.date) : new Date();

    if (isNaN(dateQuery.getTime())) {
        return res.status(400).json({ error: 'Data inválida fornecida.' });
    }
    
    const filter = {
      dataInicio: { $lte: dateQuery },
      dataFim: { $gte: dateQuery }
    };

    const ciclos = await collection.find(filter).toArray();
    res.json(ciclos);

  } catch (error) {
    console.error('❌ Erro ao processar requisição GET /ciclos:', error);
    res.status(500).json({ 
        error: 'Erro interno do servidor', 
        details: error.message 
    });
  }
});


// =========================================================================
// ROTA 2: Execução de Aggregation (POST /aggregate) - NOVA ROTA
// =========================================================================
// O nome da collection é passado via query parameter (ex: /aggregate?collection=Ciclo)
app.post('/aggregate', async (req, res) => {
    const collection = req.query.collection;
    const pipeline = req.body; // O corpo da requisição é o array do pipeline
    
    if (!collection) {
        return res.status(400).json({ error: 'Parâmetro de coleção (query: ?collection=NomeDaCollection) é obrigatório.' });
    }
    
    if (!Array.isArray(pipeline) || pipeline.length === 0) {
        return res.status(400).json({ error: 'O corpo da requisição deve ser um array JSON contendo o pipeline de agregação.' });
    }

    try {
        const db = client.db(dbName);
        const mongoCollection = db.collection(collection);

        // --- CONVERSÃO DE STRINGS PARA OBJETOS MONGODB ---
        // Regex simples para verificar strings no formato ISO 8601
        const ISODateRegex = /\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d+([+-][0-2]\d:[0-5]\d|Z)/;

        // Garante que o n8n possa enviar IDs (strings, convertidos para ObjectId) e Datas (strings, convertidas para Date)
        const processPipeline = (stage) => {
            // Itera sobre as chaves de um objeto (Stage)
            for (const key in stage) {
                if (typeof stage[key] === 'object' && stage[key] !== null) {
                    // Chamada recursiva para tratar sub-objetos
                    processPipeline(stage[key]);
                } else {
                    // 1. CONVERSÃO DE OBJECT ID (EXISTENTE)
                    if ((key === '_id' || key.toLowerCase().includes('idproduto') || key.toLowerCase().includes('foreignfield')) && typeof stage[key] === 'string' && ObjectId.isValid(stage[key])) {
                        stage[key] = new ObjectId(stage[key]);
                    } 
                    
                    // 2. CONVERSÃO DE DATA (NOVO)
                    // Se for string, e parecer uma data ISO 8601, converte para objeto Date
                    else if (typeof stage[key] === 'string' && ISODateRegex.test(stage[key]) && !isNaN(new Date(stage[key]).getTime())) {
                        stage[key] = new Date(stage[key]);
                    }
                }
            }
        };

        // Aplica a conversão em cada etapa do pipeline
        const processedPipeline = JSON.parse(JSON.stringify(pipeline)); // Clone para não modificar o original
        processedPipeline.forEach(processPipeline);
        
        // Executa o aggregation
        const result = await mongoCollection.aggregate(processedPipeline).toArray();

        // Retorna o array de documentos resultantes
        res.json(result);

    } catch (error) {
        console.error(`❌ Erro ao executar aggregation na coleção ${collection}:`, error);
        res.status(500).json({
            error: 'Erro ao executar o pipeline de agregação no MongoDB',
            details: error.message
        });
    }
});
// =========================================================================


// 7. Inicia o servidor Express (mantido)
app.listen(port, () => {
  console.log(`🎉 Servidor da API rodando na porta ${port}`);
});