function(doc) {
  if(doc.notes[1] === "odd") {
    emit(doc._rev, doc);
  }
}
