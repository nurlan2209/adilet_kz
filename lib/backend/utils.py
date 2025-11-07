from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    truncated = password.encode('utf-8')[:72]
    return pwd_context.hash(truncated)

def verify_password(password: str, hashed: str) -> bool:
    truncated = password.encode('utf-8')[:72]
    return pwd_context.verify(truncated, hashed)
