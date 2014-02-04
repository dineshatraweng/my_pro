$(document).ready(function(){

  $("#table1").tableDnD();
  applyEllipsis();
  $("#browse").treeview();
  $("#selectpg").selectbox();
    
 if($('.jquery-selectbox').length)  {
   var lt = $('.jquery-selectbox-item').length;
   $('.jquery-selectbox-list').css('height',lt*10+'px');
   $('.jquery-selectbox-list').css('overflow-y','auto');

 }

  var search = 'Search';
  var searchLabel1 = $('#search-box label').remove().text();

  $('#quick-find').val(searchLabel1)
  .focus(function() {
    if (this.value == searchLabel1)
      $(this).val('');

  })
  .blur(function() {
    if (this.value == '')
      $(this).val(searchLabel1);
  });


  $('#big-find').val(search)
  .focus(function() {
    if (this.value == search)
      $(this).val('');
  })
  .blur(function() {
    if (this.value == '')
      $(this).val(search);

  });
});