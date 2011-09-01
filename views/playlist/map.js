function(doc) {
    if(doc._attachments) {
        emit(doc._rev, doc._attachments);
    }
}