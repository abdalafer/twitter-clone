$(function() {
    var pathname=window.location.pathname;
    $(".panel-following-users").hide();
    $(".panel-all-users").hide();

    if (pathname == "/account/dashboard") loadTweetBox()

    function postData(method, path, form_id, success_events)
    {
        $.ajax({
            url: path,
            type: method,
            data: $(form_id).serialize(),
            success: function(data) {
                success_events();
            },
            error: function(data) {
            }
        });
    }

    function getCall(path, success_events)
    {
        $.ajax({
            type: 'get',
            url: path,
            dataType: "json",
            success: function(data){
                success_events();
            },
            error: function(XMLHttpRequest, Status){
                window.location = "/";
                //todo, produce a error response to UI
            }
        })
    }

    function loadContent(path, container)
    {
        $.ajax({
            type: 'get',
            url: path,
            dataType: "json",
            beforeSend:function(){
                //$("#loading_box").fadeIn('fast', function() {});
            },
            success: function(data){
                $(container).html(data.html);
            },
            error: function(XMLHttpRequest, Status){
                //$("#loading_box").hide();
                //$(container).empty();
                $(container).html("Error Loading");
                window.location = "/";
            }
        })
    }

    function loadTweetBox(){
        loadContent('/account/tweet_box/', ".tweet_box_container");
    }

    $("body").on('click','.btn_user_summary', function(){
        var username = $(this).data("username");
        loadContent('/account/user_summary/'+username, ".user_summary_container");
        $('#myModal').modal('show');
    });

    $("body").on('click','.btn_follow', function(){
        var uid = $(this).data("uid");
        var success_events = function(data)
        {
            loadContent('/account/show_all_users/', ".all_users_container");
        }
        getCall('/account/follow/'+uid, success_events);
    });

    $("body").on('click','.btn_unfollow', function(){
        var uid = $(this).data("uid");
        var success_events = function(data)
        {
            loadContent("/account/show_following_users", ".following_container");
        }
        getCall("/account/unfollow/"+uid, success_events);
    });

    $(".button-all-users").on('click', function(){
        loadContent('/account/show_all_users/', ".all_users_container");

        $(".button-following-users").removeClass("active");
        $(this).addClass("active");
        $(".panel-following-users").hide();
        $(".panel-all-users").show();
    })

    $(".button-following-users").on('click', function(){
        loadContent('/account/show_following_users/', ".following_container");

        $(".button-all-users").removeClass("active");
        $(this).addClass("active");
        $(".panel-all-users").hide();
        $(".panel-following-users").show();
    })

    $("#new_tweet").submit(function( event ) {
        event.preventDefault();
        var success_events = function(data){
            $('#tweet_tweet_message').val('');
            loadTweetBox();
        }
        postData("POST", "/account/tweet/", "#new_tweet", success_events);
    });

});