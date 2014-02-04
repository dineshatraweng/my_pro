console.log(google);
google.load('search', '1', {language : 'en', style : google.loader.themes.SHINY});
google.setOnLoadCallback(function() {
  var customSearchControl = new google.search.CustomSearchControl('010846430575534959222:t-i_dnqkkmw');
  customSearchControl.setResultSetSize(google.search.Search.FILTERED_CSE_RESULTSET);
  customSearchControl.draw('cse');
}, true);
