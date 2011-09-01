function(head, req) {
    var row;
    start({
        "headers": {
            "Content-Type" : "text/csv",
            "Content-Disposition" : "attachment; filename=out.csv"
        }
    });
    while(row = getRow()) {
        send(row.value[0].join(',') + "\n");
    }
}