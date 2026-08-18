"""Scripts operacionais do backend Atlas.

Os scripts deste pacote são executados com ``python -m scripts.<modulo>``
a partir de ``/app`` no container de produção. Dessa forma, o pacote
principal ``app`` permanece disponível no ``sys.path`` e os mesmos imports
funcionam no Render, em desenvolvimento e nos testes.
"""
