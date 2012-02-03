var upload = false;
var InlineUpload = 
{
	dialog: null,
	block: '',
	offset: {},
	options: {
		container_class: 'markItUpInlineUpload',
		form_id: 'inline_upload_form',
		action: '/page/imageUpload.cfm',
		inputs: {
			file: { label: 'File', id: 'inline_upload_file1', name: 'inline_upload_file1' }
		},
		submit: { id: 'inline_upload_submit', value: 'upload' },
		close: 'inline_upload_close',
		iframe: 'inline_upload_iframe'
	},
	display: function(hash,uploadOption)
	{	
		if(uploadOption){
		if( ! $('.markItUpInlineUpload').length)
		{
			var self = this;
		
		/* Find position of toolbar. The dialog will inserted into the DOM elsewhere
		 * but has position: absolute. x is to avoid nesting the upload form inside
		 * the original. The dialog's offset from the toolbar position is adjusted in
		 * the stylesheet with the margin rule.
		 */
		this.offset = $(hash.textarea).prev('.markItUpHeader').offset();
		
		/* We want to build this fresh each time to avoid ID conflicts in case of
		 * multiple editors. This also means the form elements don't need to be
		 * cleared out.
		 */
		this.dialog = $([
			'<div class="',
			this.options.container_class,
			'"><div><form id="',
			this.options.form_id,
			'" action="',
			this.options.action,
			'" target="',
			this.options.iframe,
			'" method="post" enctype="multipart/form-data"><label for="',
			this.options.inputs.file.id,
			'">',
			this.options.inputs.file.label,
			'</label><input name="',
			this.options.inputs.file.name,
			'" id="',
			this.options.inputs.file.id,
			'" type="file" /><input id="',
			this.options.submit.id,
			'" type="button" value="',
			this.options.submit.value,
			'" /></form><div id="',
			this.options.close,
			'"></div><iframe id="',
			this.options.iframe,
			'" name="',
			this.options.iframe,
			'" src="/page/imageUpload.cfm"></iframe></div></div>',
		].join(''))
			.appendTo(document.body)
			.hide()
			.css("position", "absolute")
			.css('top', this.offset.top)
			.css('left', this.offset.left);
				
		
		//init submit button
		 
		$('#'+this.options.submit.id).click(function()
		{
			if($('#inline_upload_file1').val() == ''){
				alert('Please select a file to upload');
				return false;
			}
			upload = true;
			$('#'+self.options.form_id).submit().fadeTo('fast', 0.2);
		});
	
				
		// init cancel button
		 
		$('#'+this.options.close).click(this.cleanUp);
		
		
		// form response will be sent to the iframe
		 
		$('#'+this.options.iframe).bind('load', function()
		{
			var result = document.getElementById(''+self.options.iframe).contentWindow.document.body.innerHTML;
			if(upload){
					$('#resultContainer').html(result);
					$(".module .products a").click(function() {
						src = $(this).attr("href");
						alt = $(this).attr("title");
						//$.markItUp( {replaceWith:'<img src="'+src+'" alt="'+alt+'" (!( class="[![Class]!]")!) />' });
						$.markItUp( {replaceWith:'[[Image:'+src+']]' });
						$("#linkPlugin").fadeOut().css("zIndex", 11);
						return false;
					}); 
					InlineUpload.dialog.fadeOut().remove();
					
					$("#linkPlugin").fadeIn().css('top', self.offset.top-80).css('left', self.offset.left+460).css("zIndex", 11);
					upload = false;
			}
		});
		
			// Finally, display the dialog
			this.dialog.fadeIn('slow');
			}
		
	}else{
		this.offset = $(hash.textarea).prev('.markItUpHeader').offset();
		$('#resultContainer').load('/page/imageUpload.cfm','',function() {
				$(".module .products a").click(function() {
						src = $(this).attr("href");
						alt = $(this).attr("title");
						//$.markItUp( {replaceWith:'<img src="'+src+'" alt="'+alt+'" (!( class="[![Class]!]")!) />' });
						$.markItUp( {replaceWith:'[[Image:'+src+']]' });
						$("#linkPlugin").fadeOut().css("zIndex", 11);
						return false;
					}); 
			});
		
		$("#linkPlugin").fadeIn().css('top', this.offset.top-80).css('left', this.offset.left+460).css("zIndex", 11);
		
		}
	},
	cleanUp: function()
	{
		InlineUpload.dialog.fadeOut().remove();
	}
};