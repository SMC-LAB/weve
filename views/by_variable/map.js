function(doc) {
    if (doc.ratings && doc.descriptors) {
        for (var r in doc.ratings) {
            for (var d in doc.descriptors) {
                emit([r,d], [doc.ratings[r], doc.descriptors[d]]);
            }
        }
    }
}