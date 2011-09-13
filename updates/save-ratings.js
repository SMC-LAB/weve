function(doc, req) {

    if (!doc.ratings) {
        doc.ratings = {};
    }
    
    for (var word in req.form) {

        if (!doc.ratings[word]) {
            doc.ratings[word] = {};
        }
        doc.ratings[word]['abc'] = req.form[word];
    }

    return [doc, "Done!"];
}
