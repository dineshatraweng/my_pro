function sortDocuments(){
$('.product-docs').sortable();

$('.save-document-order').click(function(){
  var button = $(this);
  var reorder_documents = $('.product-docs').sortable("serialize");
  var url= button.attr('href');
  $.post(url,reorder_documents,function(data){
    if($('#notice').length < 1)
    {
      var add_element = "<p id='notice'>Document Order Saved Successfully</p>";
      button.parent().append(add_element);
      $('#notice').fadeOut(5000,function(){
        $(this).remove();
      });
    }

    $('.product-docs').sortable("refresh");

  });
  return false;
});
}
