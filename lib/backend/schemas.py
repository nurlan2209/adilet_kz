from pydantic import BaseModel

class UserRegister(BaseModel):
    name: str
    surname: str
    email: str
    phone: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    surname: str
    email: str
    phone: str

    class Config:
        orm_mode = True
