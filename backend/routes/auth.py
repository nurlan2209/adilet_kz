from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from passlib.hash import bcrypt
import jwt
from datetime import datetime, timedelta
from database import get_database
from bson import ObjectId
import os
from dotenv import load_dotenv

# Загружаем секретный ключ из .env
load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY", "fallback_secret_key")

router = APIRouter(prefix="/auth", tags=["auth"])

# Модели данных
class RegisterModel(BaseModel):
    name: str
    surname: str
    email: EmailStr
    phone: str
    password: str

class LoginModel(BaseModel):
    email: EmailStr
    password: str

@router.get("/ping")
async def ping():
    return {"status": "ok"}

@router.post("/register")
async def register(data: RegisterModel):
    db = await get_database()
    
    # Проверяем, есть ли пользователь
    existing_user = await db.users.find_one({"email": data.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    # Хэшируем пароль
    hashed_pw = bcrypt.hash(data.password)
    user_data = {
        "name": data.name,
        "surname": data.surname,
        "email": data.email,
        "phone": data.phone,
        "password": hashed_pw,
        "created_at": datetime.utcnow()
    }

    # Сохраняем пользователя в MongoDB
    result = await db.users.insert_one(user_data)

    # Генерируем JWT
    token = jwt.encode(
        {"sub": data.email, "exp": datetime.utcnow() + timedelta(hours=1)},
        SECRET_KEY,
        algorithm="HS256",
    )

    # Возвращаем данные без пароля и с _id как строкой
    user_response = {
        "id": str(result.inserted_id),
        "name": data.name,
        "surname": data.surname,
        "email": data.email,
        "phone": data.phone,
    }

    return {"status": "success", "token": token, "user": user_response}

@router.post("/login")
async def login(data: LoginModel):
    db = await get_database()
    
    user = await db.users.find_one({"email": data.email})
    if not user or not bcrypt.verify(data.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Генерируем JWT
    token = jwt.encode(
        {"sub": data.email, "exp": datetime.utcnow() + timedelta(hours=1)},
        SECRET_KEY,
        algorithm="HS256",
    )

    # Возвращаем данные без пароля, _id преобразуем в строку
    user_response = {k: str(v) if isinstance(v, ObjectId) else v for k, v in user.items() if k != "password"}

    return {"status": "success", "token": token, "user": user_response}
