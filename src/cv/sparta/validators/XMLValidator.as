package cv.sparta.validators {
	
	import mx.validators.Validator;
	import mx.validators.ValidationResult;

	public class XMLValidator extends Validator	{
		
		public function XMLValidator() {
			super();
		}
		
		public static function validateXML(validator:XMLValidator, value:Object, baseField:String = null):Array {
			var results:Array = [];
	
			var val:String = value != null ? String(value) : "";
			
			// First letter must be <
			if(val.indexOf("<") != 0) {
				results.push(new ValidationResult(true, baseField, "invalidStart", "Invalid XML, must start with a '<'."));
				return results;
			}
			
			try {
				var xml:XML = XML(val);
			} catch (err:TypeError) {
				results.push(new ValidationResult(true, baseField, "invalidXML", "Invalid XML String."));
				return results;
			}
	
			return results;
		}
		
		override protected function doValidation(value:Object):Array {
			var results:Array = super.doValidation(value);
			
			// Return if there are errors
			// or if the required property is set to false and length is 0.
			var val:String = value ? String(value) : "";
			
			if (results.length > 0 || ((val.length == 0) && !required)) {
				return results;
			} else {
			    return XMLValidator.validateXML(this, value, null);
			}
	    }
	}
}