$(document).ready(function(){

	$(".product-instructions-items").hide();
	$("label").click(function(e){
			e.preventDefault();
			$(".product-instructions-items", $(this).parent()).slideToggle();        
	});

  /*** for back to top button***/
  $("#back-top").hide();
	$(function () {
		$(window).scroll(function () {
			if ($(this).scrollTop() > 100) {
				$('#back-top').fadeIn();
			} else {
				$('#back-top').fadeOut();
			}
		});

		$('#back-top').click(function () {
			$('body,html').animate({
				scrollTop: 0
			}, 500);
			return false;
		});
	});
});