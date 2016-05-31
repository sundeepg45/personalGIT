public class IntegrationObjectsUtils {

    public static Datetime parseDatetime(String oracleDt) {
        if (oracleDt == null) {
            return null;
        }
        oracleDt = '"' + oracleDt + '.000Z"';
        return (Datetime) json.deserialize(oracleDt, Datetime.class);
    }

    public static String formatDatetime(Datetime dt) {
        if (dt == null) {
            return null;
        }
        String s = json.serialize(dt.date());
        s = s.substring(1,11) + 'T00:00:00';
        return s;
    }
}