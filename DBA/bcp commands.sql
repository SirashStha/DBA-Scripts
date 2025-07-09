bcp INFINITY_020_001.dbo.DOC_STORE out "D:\DocStore\test_row.bcp" -n -S 192.168.50.44 -U sa -P infodev

bcp INFINITY_020_001.dbo.DOC_STORE format nul -n -x -f "D:\DocStore\docstore.fmt" -S 192.168.50.44 -U sa -P infodev

bcp DOC_STORE_BAK.dbo.DOC_STORE in "D:\DocStore\test_row.bcp" -f "D:\DocStore\docstore.fmt" -S 192.168.20.32 -U sa -P infodev






TEST

bcp "SELECT TOP 1 * FROM INFINITY_020_001.dbo.DOC_STORE" queryout "D:\DocStore\test_row.bcp" -n -S 192.168.50.44 -U sa -P infodev