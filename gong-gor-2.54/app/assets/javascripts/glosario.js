function glosario() {
if (navigator.appName!='Microsoft Internet Explorer') {
	od((typeof(window["getSelection"])=="undefined"?document.getSelection():window.getSelection().toString()));
	}
else {
	var t = document.selection.createRange();
	if(document.selection.type == 'Text' && t.text>'') {
		document.selection.empty();
		od(t.text);}
   }
function od(t) {
t = t.replace(/[́!.:?,;"]/g, '').replace(/[\n\t ]/g, ' ').replace(/^\s+|\s+$/, '');
if (t) window.open('/glosario.html#' + encodeURIComponent(t).toUpperCase(), 'Glosario', 'width=700,height=500,resizable=1,menubar=0,scrollbars=1,status=0,titlebar=0,toolbar=0,location=0,personalbar=0');
}   
};
status='Haz doble-click sobre cualquier palabra.';
if (navigator.appName=='Microsoft Internet Explorer') document.ondblclick=glosario; //works for IE only. For other browsers add <body ondblclick="glosario()">
