function(doc) {
    if (doc._id.length == 57) {
        emit(doc._id, doc._rev);
    }
}
