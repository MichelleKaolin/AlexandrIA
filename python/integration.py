import mysql.connector
from fastapi import FastAPI, UploadFile, File

app = FastAPI()

db_config = {
    'user': 'root',
    'password': 'sua_senha',
    'host': 'localhost',
    'database': 'alexandria_db'
}

@app.post("/ia/processar")
async def processar_e_salvar(doc_id: int, file: UploadFile = File(...)):
    resumo_gerado = "Resultado da Chain de IA (LangChain)"
    
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    query = "UPDATE documentos SET resumo_ia = %s WHERE id = %s"
    cursor.execute(query, (resumo_gerado, doc_id))
    conn.commit()
    cursor.close()
    conn.close()
    
    return {"status": "sucesso", "resumo": resumo_gerado}