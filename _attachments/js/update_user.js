function update_user() {
    var that = this;
    var form_data = $(this).serializeArray();
    $.couch.session({
        success:function(d) {
            if (!d.userCtx) {
                return false;
            }
            var id = 'org.couchdb.user:' + d.userCtx.name;
            console.log("update user: " + id);
            $.getJSON("/_users/" + id, function(data) {
                if ($(that).attr('action') === "http://smc.inescporto.pt/shakeit/") {
                    data.end_time = Date();
                }
                else {
                    console.log($(that).attr('action'));
                }
                console.log($(that).attr('action'));
                for (var i = 0; i < form_data.length; i++) {
                    data[form_data[i].name] = form_data[i].value;
                }
                $.ajax({
                    type: "PUT",
                    url:"/_users/" + id,
                    dataType: 'json',
                    data: JSON.stringify(data),
                    success:function(d) {window.location.replace($(that).attr('action'));}
                });
            });
        }
    })
    return false;
}
