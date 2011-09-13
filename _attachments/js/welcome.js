$.fn.serializeObject = function()
{
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
        if (o[this.name] !== undefined) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};

function gen_id(o) {
    return hex_sha1(new Date() + JSON.stringify(o));
}

function submit_form() {

    var form = $('#myform');
    var data = form.serializeObject();
    var id   = gen_id(data);
    data.name = id;

    $.couch.signup(data, id, {
        success:function(d,s,x) {
            console.log("Signing up " + id);
            $.couch.login({
                name:id,
                password:id,
                success:function() {
                    console.log("Logging in " + id);
                    form.submit();
                }
            });
        },
        error:function(r,s,e) {
            console.log("Couldn't sign up" + id + " because: " + e);
            $('#form_name').attr("class", "error");
            $('#form_name').focus(function() {$('#form_name').removeAttr("class")});
        }
    });

    return false;
}

function validate_submission() {
    var form = $('#myform');
    var name = form.find('#form_name');
    return name.val() != "";
}
