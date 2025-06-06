#!/bin/bash
python -m spacy download es_core_news_sm
uvicorn app.main:app --host 0.0.0.0 --port 10000
