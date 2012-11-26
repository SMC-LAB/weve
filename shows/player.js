function(doc, req) {

    if (!doc) {
        return {
            "code" : 403,
            "body" : "Forbidden"
        };  
    }

    // !json templates.player
    // !code vendor/couchapp/lib/mustache.js

    var files = [];
    var db    = req.path[0];
    var media = {};

    for (var file in doc._attachments) {

        var src   = ['', db, doc._id, file].join('/');
        var type  = doc._attachments[file].content_type;
        var title = doc._id;
        var ext   = file.split('.')[1];
        media[ext] = src;

        files.push({"src":src, "type":type, "title":title});
    }

    return Mustache.to_html(templates.player, {"files":files, "media":JSON.stringify(media)});
}
