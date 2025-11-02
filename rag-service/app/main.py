from fastapi import FastAPI, Query

app = FastAPI(title="LudaCRIS RAG Service")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/rag/answer")
def rag_answer(q: str = Query(..., min_length=2)):
    # Placeholder: wire in hybrid retrieval later
    return {"query": q, "answer": "RAG placeholder", "citations": []}