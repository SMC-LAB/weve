function init(docs) {
    return {
        next:function(){docs.rows.shift(); return docs.rows[0].id;},
        current:function(){return docs.rows[0].id;}
    };
}
function load_form(id) {
    console.log("load_form(): " + id);
    var height = window.innerHeight / 2;
    var width = window.innerWidth / 2;
    $('#save-ratings-iframe').attr('height', height);
    $('#save-ratings-iframe').attr('width', width);
    $('#save-ratings-iframe').attr('src', '_show/range/' + id);
}
function load_player(id) {
    console.log("load_player(): " + id);
    var height = window.innerHeight / 2;
    var width = window.innerWidth / 2;
    $('#player-iframe').attr('height', height);
    $('#player-iframe').attr('width', width);
    $('#player-iframe').attr('src', '_show/player/' + id);
}
function submit_form() {
    var form = $('#save-ratings-iframe').contents().find('#save-ratings-form');
    var data = form.serializeArray();
    var id   = ids.current();
    var action = "_update/save-ratings/" + id;

    form.submit(function() {
        console.log("submit_form(): " + id);
        $.ajax({
            type: "POST",
            url: action,
            data: data,
            retries: 0,
            maxretries: 10,
            success: function() {
                //console.log("No conflicts");
            },
            error: function(req, status, error) {
                if (req.status === 409 || status === 'timeout') {
                    if (this.retries <= this.maxretries) {
                        $.ajax(this);
                        return;
                    }
                    else {
                        console.log("Couldn't update document due to conflicts after " + this.retries);
                    }
                }
                console.log("Couldn't update document: " + req.status + "\n" + status + "\n" + error);
            }
        });
        return true;
    });

    id = ids.next();
    load_form(id);
    load_player(id);

    return true;
}
           
var ids;
$(document).ready(function() {
    var dbname = document.location.href.split('/')[3];
    var view   = 'random'
    $db = $.couch.db(dbname);
    $db.view("weve/" + view, {
        success: function(data) {
            ids = init(data);
            var id = ids.current();
            load_form(id);
            load_player(id);
        },
        error: function(status) {
            console.log(status);
        },
        reduce: false
    });
});
