from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.auth import router as auth_router  # 👈 правильный путь

app = FastAPI()

# Разрешаем Flutter доступ
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # потом можно ограничить, например ["http://localhost:8080"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем маршруты из routes/auth.py
app.include_router(auth_router)

@app.get("/")
async def root():
    return {"message": "FastAPI + MongoDB connected!"}
