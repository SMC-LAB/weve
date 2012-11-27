function(doc) {
  if(doc.notes[1] === "even") {
    emit(doc._rev, doc);
  }
}
