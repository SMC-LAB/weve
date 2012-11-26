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
  data.user_agent = navigator.userAgent;
  data.start_time = Date();

  $.couch.logout({
    success : function() {
      console.log("Logging out");
      $.couch.signup(data, id, {
        success:function(d,s,x) {
          console.log("Signing up " + id);
          $.couch.login({
            name:id,
            password:id,
            success:function() {
              console.log("Logging in " + id);
              redirect("instructions.html");
            }
          })
        }
      })
    }
  });


  return false;
}
