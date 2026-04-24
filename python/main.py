from fastapi import FastAPI, UploadFile, File, HTTPException, Security, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from langchain.document_loaders import PyPDFLoader
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings
from langchain.chains import RetrievalQA
from langchain.chat_models import ChatOpenAI
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

def verificar_token(auth: HTTPAuthorizationCredentials = Security(security)):
    if auth.credentials != "seu_token_secreto_fatec":
        raise HTTPException(status_code=403, detail="Acesso não autorizado")
    return auth.credentials

embeddings = OpenAIEmbeddings()
llm = ChatOpenAI(model_name="gpt-3.5-turbo", temperature=0)

@app.post("/ia/resumir")
async def gerar_resumo(file: UploadFile = File(...), token: str = Depends(verificar_token)):
    path = f"temp_{file.filename}"
    try:
        with open(path, "wb") as buffer:
            buffer.write(await file.read())
        
        loader = PyPDFLoader(path)
        pages = loader.load_and_split()
        
        vectorstore = Chroma.from_documents(pages, embeddings)
        
        qa_chain = RetrievalQA.from_chain_type(
            llm, 
            chain_type="stuff", 
            retriever=vectorstore.as_retriever()
        )
        
        resumo = qa_chain.run("Gere um resumo acadêmico ABNT deste documento.")
        return {"resumo": resumo}
    
    finally:
        if os.path.exists(path):
            os.remove(path)