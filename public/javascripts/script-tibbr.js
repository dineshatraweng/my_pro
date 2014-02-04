$(document).ready(function () {
     function loading(){
         $("#loading").show();
         $('.contact-form').hide();
     }

    function stoploading()
    {
        $("#loading").hide();
        $('.contact-form').show();

    }
    /*========================================= Slidder code ==========================================================*/

    $('.slide-handle').live('click',function(event){
        var $obj = $(this).parent(),
            containerWidth = $obj.outerWidth();

        event.preventDefault();

        if($obj.hasClass('open')){
            $obj.animate({right:'-'+containerWidth},300).removeClass('open');
            $('.slide-handle').css('background','url("images/comment_open_new.png") no-repeat scroll center center #4083C5');

        }else{
            $obj.animate({right:0},300).addClass('open');
            $('.slide-handle').css('background','url("images/comment_close_new.png") no-repeat scroll center center #4083C5');
        }

    });

    /*========================================= login Form ============================================================*/
    $('#login-tabs').tabs();

    if($('.set-focus-here').length > 0){
        $('.set-focus-here').focus();
    }

    /*========================================== reply form ===========================================================*/
    function getParameters(url) {
        var searchString = url.search.split("?")[1]      // url is a  location object
            , params = searchString.split("&")
            , hash = {}
            ;
        for (var i = 0; i < params.length; i++) {
            var val = params[i].split("=");
            hash[unescape(val[0])] = unescape(val[1]);
        }
        return hash;
    }
    function getShowParentURL()
    {
        var url_string = window.parent.findURL();
        index = url_string.lastIndexOf('#');
        if (index != -1)
        {
            var hash_removed_url = url_string.substring(0, url_string.lastIndexOf('#')).replace(/[^a-zA-Z0-9]/g,'_');
            var hash = url_string.substring(url_string.lastIndexOf('#')+1,url_string.length);
            return '?url='+hash_removed_url+'&hash='+hash;
        }
        else
        {
            return '?url='+url_string.replace(/[^a-zA-Z0-9]/g,'_');
        }
    }
    $('#product-tabs').tabs({
        select: function(event, ui) {
            loading();
            var product_id = getParameters(window.parent.window.location).product;
            switch(ui.index)
            {
                case 0:
                    window.location = '/tibbr_integration/'+product_id+getShowParentURL();
                    break;
                case 1:
                    window.location = '/tibbr_integration/'+product_id;
                    break;
            }
        }
    } );



    $('.reply').live('click',function(event){
        $('.reply-content').show();

    });

    if(typeof($.fn.readmore) != 'undefined')
    {
        $('.content').readmore(
            {substr_len : 100}
        );
    }
    function delete_post(post_id)
    {
        $.get('/tibbr_integration/' + post_id +'/destroy_post', function(data){
                window.location = redirect_url;
            }
        );
    }

    $('.delete-comment-link').live('click',function()
    {
        var siblings = [];
        siblings.push($(this).parent().siblings('.tibbr-user-name'));
        siblings.push($(this).parent().siblings('.date-post'));
        siblings.push($(this).parent().siblings('.content'));
        siblings.push($(this).parent().siblings('.reply-list'));
        siblings.push($(this).parent('.user-actions'));
        $.each(siblings,function(index,sibling)
        {
            $(sibling).addClass('hidden');
        });
        var shown = $(this).parent().siblings('.confirm-delete')
        $(shown).removeClass('hidden');
    });


    $('.cancel-button-comment').live('click',function()
    {
        var siblings = [];
        siblings.push($(this).parent().siblings('.tibbr-user-name'));
        siblings.push($(this).parent().siblings('.date-post'));
        siblings.push($(this).parent().siblings('.content'));
        siblings.push($(this).parent().siblings('.reply-list'));
        siblings.push($(this).parent().siblings('.user-actions'));
        $.each(siblings,function(index,sibling)
        {
            $(sibling).removeClass('hidden');
        });
        var hide = $(this).parent('.confirm-delete')
        $(hide).addClass('hidden');
    });

    $('.accept-del-comment').live('click',function()
    {
        var delete_link = $(this).parent().siblings('.user-actions').find('.delete-comment-link');
        reply_id = delete_link.attr('name');

        delete_post(reply_id);
    });

    $('.delete-reply-link').live('click',function()
    {
        var siblings = [];
        siblings.push($(this).parent().siblings('.content'));
        siblings.push($(this).parent().siblings('.reply-info'));
        siblings.push($(this).parent('.date-post'));
        $.each(siblings,function(index,sibling)
        {
            $(sibling).addClass('hidden');
        });
        var shown = $(this).parent().siblings('.confirm-delete')
        $(shown).removeClass('hidden');
    });

    $('.cancel-button-reply').live('click',function()
    {
        var siblings = [];
        siblings.push($(this).parent().siblings('.content'));
        siblings.push($(this).parent().siblings('.reply-info'));
        siblings.push($(this).parent().siblings('.date-post'));
        $.each(siblings,function(index,sibling)
        {
            $(sibling).removeClass('hidden');
        });
        var shown = $(this).parent('.confirm-delete');
        $(shown).addClass('hidden');
    });

    $('.accept-del-reply').live('click',function()
    {
        var delete_link = $(this).parent().siblings('.date-post').find('.delete-reply-link');
        reply_id = delete_link.attr('name');

        delete_post(reply_id);
    });

    $('.reply-link').live('click',function(){
        var html = '<li class="reply-block">';
        html += '<div class="reply-wrap">';
        html += '<div class="reply-envelope clearfix">'
        html += '<textarea class="reply-textarea set-focus-here" rows="2" cols="20" placeholder="Enter text"></textarea>';
        html += '<a href="#" class="reply-btn">';
        html += '<span class="comment-reply">Reply</span>';
        html += '</a>';
        html += '</div>';
        html += '</div>';
        html += '</li>';
        $(".reply-textarea").removeClass('set-focus-here')
        var slider = $(this).parent().siblings('.meta').children('li');
        var meta = $(this).parent().siblings('.meta');
        if(slider.hasClass("reply-block")){
            $(this).parent().parent().children('ul.meta').children('.reply-block').html('');
            $(this).parent().parent().children('ul.meta').children('.reply-block').removeClass('reply-block');
            $(this).parent().parent().children('ul.meta').removeClass('reply-arrow');
        }else{
            meta.append(html);
            $(this).parent().parent().children('ul.meta').addClass('reply-arrow');
        };
        $('.set-focus-here').focus();
    });



    /* to show n hide the replies*/
    $('.profile-name').live('click',function(){
        var sib=$(this).parent().siblings('.info');
        $(sib).each(function()
        {
            if($(this).hasClass('hidden'))
            {
                $(this).removeClass('hidden');
            }
            else{
                $(this).addClass('hidden');
            }
        });


    });



    /*placeholder*/
    $('[placeholder]').focus(function () {
        var input = $(this);
        if (input.val() == input.attr('placeholder')) {
            input.val('');
            input.removeClass('placeholder');
        }
    }).blur(function () {
            var input = $(this);
            if (input.val() == '' || input.val() == input.attr('placeholder')) {
                input.addClass('placeholder');
                input.val(input.attr('placeholder'));
            }
        }).blur().parents('form').submit(function () {
            $(this).find('[placeholder]').each(function () {
                var input = $(this);
                if (input.val() == input.attr('placeholder')) {
                    input.val('');
                }
            })

        });

    if(typeof(active_tab) != 'undefined')
    {
        $('#tib-post_tib-box').removeClass('ui-state-active ui-tabs-selected');
        $('#'+active_tab).addClass('ui-state-active ui-tabs-selected');
    }

    /* ============================ posting the tibs and reply to the application ======================================*/


    $('#tib-btn').click(function()
    {
        if ($.trim($('#tib-text').val()) && $.trim($('#tib-text').val()) != "Enter comments on the currently displayed section of the documentation" && $.trim($('#tib-text').val())!= "Enter general comments on this product's documentation" )
        {
            $('#tib-btn').css('display','none');
            $('.post-tib').append('<img src="/images/ajax-loader.gif" style="float:right;margin: 5 0;">');
            active_tab =  $('#active_tab').val();
            product_id = getParameters(window.parent.window.location).product;
            link = window.parent.findURL();
            msg = $('#tib-text').val();
            if (active_tab == 'tib-post_question-post')
            {
                var form_data = {message:{content:msg},prod:product_id};
            }
            else
            {
                var form_data = {message:{content:msg, url:link},prod:product_id};
            }
            $.post('/tibbr_integration/create_post',form_data, function(data){
                    try
                    {
                        window.location = product_url;
                    }
                    catch(err)
                    {
                      window.location.href = window.parent.getShowURL();
                    }

                }
            );
        }
    });

    $('.reply-btn').live('click',function()
    {
        comment_text = $(this).siblings('textarea')[0];

        if ($.trim($(comment_text).val()))
        {
            $(this).css('background','none repeat scroll 0 0 transparent');
            $(this).html('<img src="/images/ajax-loader.gif" style="float:right;margin: 3 0 0 0;">');
            product_id = getParameters(window.parent.window.location).product;
            link = window.parent.findURL();
            parent_class = $($(this).parent().parent().parent().parent().siblings('div')[0]).attr('id');
            msg = $(comment_text).val();
            if (active_tab == 'tib-post_question-post')
            {
                var form_data = {message:{content:msg,parent_id:parent_class},prod:product_id};
            }
            else
            {
                var form_data = {message:{content:msg, url:link,parent_id:parent_class},prod:product_id};
            }
            $.post('/tibbr_integration/create_post',form_data, function(data){
                    window.location = product_url;
                }
            );
        }

    });

    stoploading();
    /*=================================================================================================================*/
});
