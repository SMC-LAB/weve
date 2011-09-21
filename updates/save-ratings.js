function(doc, req) {

    if (!doc.ratings) {
        doc.ratings = {};
    }

    var user = req.userCtx.name;

    for (var word in req.form) {

        if (!doc.ratings[word]) {
            doc.ratings[word] = {};
        }
        doc.ratings[word][user] = req.form[word];
    }

    return [doc, "Done!"];
}
