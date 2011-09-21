function init_weve(docs) {
    return {
        next:function(){docs.rows.shift(); return docs.rows[0].id;},
        current:function(){return docs.rows[0].id;}
    };
}
function load_form(id) {
    console.log("load_form(): " + id);
    $('div#tags').load("_show/range/" + id);
}
function load_player(id) {
    console.log("load_player(): " + id);
    $('div#player').load("_show/player/" + id);    
}
function submit_form() {
    if (!ids.current) return false;
    var form = $('#save-ratings-form');
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
                    }
                    else {
                        console.log("Couldn't update document due to conflicts after " + this.retries);
                        return false;
                    }
                }
            }
        });
    });

    id = ids.next();
    load_form(id);
    load_player(id);

    return false;
}
function validate_submission() {
    var form = $('#save-ratings-form');
    var labels = form.find('label');
    var valid = true;
    for (var i = 0; i < labels.contents().length; i++) {
        console.log(i + ": checking " + labels.eq(i).text());
        if (labels.eq(i).text() === 'Not yet rated') {
            labels.eq(i).css('color', 'red');
            valid = false;
        }
    }
    return valid;
}
function player_playing() {
    console.log("playing");
    var form = $('#save-ratings-form');
    form.find('.likert-item').attr('disabled', 'disabled');
    form.find('#submit-button').attr('disabled', 'disabled');
    form.find('#submit-button').attr('value', 'Wait');
}
function player_paused() {
    console.log("paused");
    var form = $('#save-ratings-form');
    form.find('.likert-item').removeAttr('disabled');
    form.find('#submit-button').removeAttr('disabled');
    form.find('#submit-button').attr('value', 'Next');
}

var ids;
function start_weve() {
    $(document).ready(function() {
        var dbname = document.location.href.split('/')[3];
        var view   = 'random';

        $.getJSON('/' + dbname + '/_design/weve/config.json', function (data) {
            $('#question').html(data.question);
            // $('#disagreement').html(data.min[1]);
            // $('#agreement').html(data.max[1]);
        });

        $db = $.couch.db(dbname);
        $db.view("weve/" + view, {
            success: function(data) {
                ids = init_weve(data);
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
}
