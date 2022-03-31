using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Helpers
{
    public static class JsonHelpers
    {
        public static string GetStringValueFromJson(Logging.Logging logging, string PropertyName, JObject SourceObject, string DefaultValue, bool LogErrorIfNotFound)
        {
            string ret = "";
            if ((SourceObject.TryGetValue(PropertyName, out JToken tokenDump)) == true)
            {
                ret = tokenDump.ToString();
            }
            else
            {
                if (LogErrorIfNotFound)
                {
                    logging.LogWarning($"Json Element '{PropertyName}' not found");
                }
                ret = DefaultValue;
            }
            return ret;
        }

        public static dynamic GetDynamicValueFromJson(Logging.Logging logging, string PropertyName, JObject SourceObject, string DefaultValue, bool LogErrorIfNotFound)
        {
            dynamic ret;
            if ((SourceObject.TryGetValue(PropertyName, out JToken tokenDump)) == true)
            {
                ret = tokenDump.ToString();
            }
            else
            {
                if (LogErrorIfNotFound)
                {
                    logging.LogWarning($"Json Element '{PropertyName}' not found");
                }
                ret = DefaultValue;
            }
            return ret;
        }

        public static bool CheckForJsonProperty(string Property, JObject O)
        {
            bool ret = false;
            ret = O.TryGetValue(Property, out JToken tokenDump);
            return ret;

        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="logging"></param>
        /// <param name="propertyList"></param>
        /// <param name="jsonString"></param>
        /// <returns></returns>
        public static bool BuildJsonObjectWithValidation(Logging.Logging logging, ref JsonObjectPropertyList propertyList, string jsonString, ref JObject TargetJObject)
        {
            bool objectValid = false;
            if (IsValidJson(jsonString))
            {
                objectValid = true;
                JObject jobj = JObject.Parse(jsonString);
                foreach (JsonObjectProperty p in propertyList)
                {
                    if (CheckForJsonProperty(p.SourcePropertyName, jobj))
                    {
                        TargetJObject[p.TargetPropertyName] = jobj[(p.SourcePropertyName)];
                        p.WasFound = true;
                    }
                    else
                    {
                        if (p.RaiseErrorIfNotFound)
                        {
                            logging.LogErrors(new Exception("Property " + p.SourcePropertyName + " was not found."));
                            objectValid = false;
                        }
                        else
                        {
                            if (p.RaiseWarningIfNotFound)
                            {
                                logging.LogWarning("Property " + p.SourcePropertyName + " was not found.");
                            }
                        }

                        p.WasFound = false;
                    }
                }
            }
            else
            {
                objectValid = false;
            }
            return objectValid;
        }

        public static async Task<bool> ValidateJsonUsingSchema(Logging.Logging logging, string SchemaAsString, string JsonObjectToValidate, string ErrorComment)
        {
            if (String.IsNullOrEmpty(SchemaAsString))
            {
                SchemaAsString = "{}";
            }
            bool ret = true;
            var schema = await NJsonSchema.JsonSchema.FromJsonAsync(SchemaAsString);
            var schemaData = schema.ToJson();
            var errors = schema.Validate(JsonObjectToValidate);
            if (errors.Any())
            {

                foreach (var error in errors)
                {
                    //Supressing Errors on non required 
                    if (error.Schema.RequiredProperties.Count != 0)
                    {
                        ret = false;
                        logging.LogErrors(new Exception(ErrorComment + "Error: " + error.Path + " : " + error.Kind));
                    }
                }
            }
            return ret;
        }

        public static bool IsValidJson(string strInput)
        {
            if (string.IsNullOrWhiteSpace(strInput)) { return false; }
            strInput = strInput.Trim();
            if ((strInput.StartsWith("{") && strInput.EndsWith("}")) || //For object
                (strInput.StartsWith("[") && strInput.EndsWith("]"))) //For array
            {
                try
                {
                    var obj = JToken.Parse(strInput);
                    return true;
                }
                catch //some other exception
                {
                    return false;
                }
            }
            else
            {
                return false;
            }
        }


    }

    public class JsonObjectPropertyList : IEnumerable<JsonObjectProperty>
    {
        public JsonObjectPropertyList()
        {
            Properties = new List<JsonObjectProperty>();
        }

        public void Add(string SourcePropertyName)
        {
            Properties.Add(new JsonObjectProperty(SourcePropertyName));
        }

        public void Add(string SourcePropertyName, bool raiseErrorIfNotFound, bool raiseWarningIfNotFound)
        {
            Properties.Add(new JsonObjectProperty(SourcePropertyName, raiseErrorIfNotFound, raiseWarningIfNotFound));
        }

        public void Add(string SourcePropertyName, string TargetPropertyName, bool raiseErrorIfNotFound, bool raiseWarningIfNotFound)
        {
            Properties.Add(new JsonObjectProperty(SourcePropertyName, TargetPropertyName, raiseErrorIfNotFound, raiseWarningIfNotFound));
        }

        public IEnumerator<JsonObjectProperty> GetEnumerator()
        {
            return ((IEnumerable<JsonObjectProperty>)Properties).GetEnumerator();
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
        {
            return ((System.Collections.IEnumerable)Properties).GetEnumerator();
        }

        public List<JsonObjectProperty> Properties { get; set; }



    }
    public class JsonObjectProperty
    {
        public JsonObjectProperty(string sourcePropertyName, bool raiseErrorIfNotFound, bool raiseWarningIfNotFound)
        {
            SourcePropertyName = sourcePropertyName;
            TargetPropertyName = sourcePropertyName;
            RaiseErrorIfNotFound = raiseErrorIfNotFound;
            RaiseWarningIfNotFound = raiseWarningIfNotFound;
        }

        public JsonObjectProperty(string sourcePropertyName)
        {
            SourcePropertyName = sourcePropertyName;
            TargetPropertyName = sourcePropertyName;
            RaiseErrorIfNotFound = true;
            RaiseWarningIfNotFound = true;
        }

        public JsonObjectProperty(string sourcePropertyName, string targetPropertyName, bool raiseErrorIfNotFound, bool raiseWarningIfNotFound)
        {
            SourcePropertyName = sourcePropertyName;
            TargetPropertyName = targetPropertyName;
            RaiseErrorIfNotFound = raiseErrorIfNotFound;
            RaiseWarningIfNotFound = raiseWarningIfNotFound;
        }
        public string SourcePropertyName { get; set; }
        public string TargetPropertyName { get; set; }

        public bool RaiseErrorIfNotFound { get; set; }
        public bool RaiseWarningIfNotFound { get; set; }

        public bool WasFound { get; set; }
    }
}
