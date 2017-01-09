(function(){
	$.getJSON('/user/', function(data){
		$('#users').html(data.join(','))
		console.log(data)
	})
	$.get('/user/get', {index: 2}, function(data){
		$('#user').html(data)
		console.log(data)
	})
})()