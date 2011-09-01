function(doc, req) {

    if (!doc) {
        return {
            "code" : 403,
            "body" : "Forbidden"
        };  
    }

    // !json config
    // !json templates.range
    // !code vendor/couchapp/lib/mustache.js

    var words = [];

    for (var word in config.words) {
        words.push({
            "autofocus"  : word == 0 ? 'autofocus' : '',
            "word"       : config.words[word][0],
            "desc"       : config.words[word][1],
            "type"       : config.type,
            "min"        : config.min[0],
            "minlabel"   : config.min[1],
            "max"        : config.max[0],
            "maxlabel"   : config.max[1],
            "step"       : config.step,
            "value"      : config.value[0],
            "valuelabel" : config.value[1]
        });
    }

    return Mustache.to_html(templates.range, {
        "words":words,
        "ticks":[config.min[1], config.max[1]],
        "id":doc._id,
        "submitlabel":config.submit,
        "noteslabel" : config.notes,
    });
}