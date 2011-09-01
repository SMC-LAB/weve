function(doc, req) {

    for (var word in req.form) {
        doc.ratings[word]['pedro123'] = req.form[word];
    }
    
    return [doc, "Done!"];

    // return [doc, {
    //     "code" : 303,
    //     "headers" : {
    //         "Location" : "http://localhost:5984/groove2/_design/weve/_show/range/" + req.query.next
    //     },
    //     "body" : "redirecting"
    // }];
}
