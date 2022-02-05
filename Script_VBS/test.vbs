Const dbServer = "DESKTOP-2F8QFJM"
Const dbUserId = "DiStor_User_exec"
Const dbCatalog = "DiscontStores"
Const dbPassword = "123"

Const adOpenStatic = 3
Const adLockOptimistic = 3

Set objConnection = CreateObject("ADODB.Connection")
Set objRecordSet = CreateObject("ADODB.Recordset")

' Create an instance of Excel and add a workbook
    Set xlApp = CreateObject("Excel.Application")
    Set xlWb = xlApp.Workbooks.Add
    Set xlWs = xlWb.Worksheets("Sheet1")

' Display Excel and give user control of Excel's lifetime
    xlApp.Visible = False
    xlApp.UserControl = True

objConnection.Open _
    "Provider=SQLOLEDB;Data Source=" & dbServer & ";" & _
    "Trusted_Connection=No;Initial Catalog=" & dbCatalog &";" & _
    "User ID=" & dbUserId & ";Password=" & dbPassword & ";"

'objRecordSet.Open "SELECT * FROM [dbo].[product]", _
'        objConnection, adOpenStatic, adLockOptimistic

objRecordSet.Open "exec application.sp_query_sales_datepart '2021-01-01','2021-06-30','w','dep3','unit'", _
        objConnection, adOpenStatic, adLockOptimistic



objRecordSet.MoveFirst

' Copy field names to the first row of the worksheet
    fldCount = objRecordSet.Fields.Count
    For iCol = 1 To fldCount
        xlWs.Cells(1, iCol).Value = objRecordSet.Fields(iCol - 1).Name
    Next

' Copy the recordset to the worksheet, starting in cell A2
        xlWs.Cells(2, 1).CopyFromRecordset objRecordSet

objRecordSet.close
objConnection.close

' Release Excel references
    'objWorkbook.SaveAs(strFileName)
    xlWb.Save
    xlWb.Close
    xlApp.Quit
    
    Set xlWs = Nothing
    Set xlWb = Nothing

    Set xlApp = Nothing

'Wscript.Echo objRecordSet.RecordCount

Public Function DataToCSV(rsData )

    If ShowColumnNames Then
        For K = 0 To rsData.Fields.Count - 1
            RetStr = RetStr & ",""" & rsData.Fields(K).Name & """"
        Next

        RetStr = Mid(RetStr, 2) & vbNewLine
    End If

    RetStr = RetStr & """" & rsData.GetString(adClipString, -1, """,""", """" & vbNewLine & """", NULLStr)
    RetStr = Left(RetStr, Len(RetStr) - 3)

    DataToCSV = RetStr
End Function
