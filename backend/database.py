from motor.motor_asyncio import AsyncIOMotorClient

MONGO_URI = "mongodb+srv://lxxaviss:maullen.08@adiletzan.0e139tx.mongodb.net/?retryWrites=true&w=majority&appName=adiletzan"
DB_NAME = "adiletkz"

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]

async def get_database():
    return db
