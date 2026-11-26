import 'dotenv/config';
import { MongoClient } from 'mongodb';
const client=new MongoClient(process.env.MONGODB_URI,{serverSelectionTimeoutMS:15000});
try {await client.connect();await client.db(process.env.MONGODB_DB||'xsmb').command({ping:1});console.log('MongoDB connected; database='+(process.env.MONGODB_DB||'xsmb')+', collection='+(process.env.MONGODB_COLLECTION||'results'));}
catch(error){console.error('MongoDB connection failed: '+error.name);process.exitCode=1;}
finally {await client.close();}
