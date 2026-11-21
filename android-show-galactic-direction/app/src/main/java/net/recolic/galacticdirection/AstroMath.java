// created by Gemini 4 Hydrogen
package net.recolic.galacticdirection;

public final class AstroMath {
    public static final class Result {
        public double azTrueDeg, altDeg;
        public double lstDeg, jd;
        public double raDateDeg, decDateDeg;
        public double raJ2000Deg, decJ2000Deg;
        public double precessionRaDeg, precessionDecDeg;
        public double galLDeg, galBDeg;
        public double declDeg;
    }

    public static Result compute(double eastMag, double northMag, double up, double declDeg, double latDeg, double lonDeg, long utcMs) {
        Result r = new Result();
        r.declDeg = declDeg;

        // 1. Rotate magnetic ENU vector to true ENU using magnetic declination (+East)
        double decl = Math.toRadians(declDeg);
        double eTrue = eastMag * Math.cos(decl) + northMag * Math.sin(decl);
        double nTrue = -eastMag * Math.sin(decl) + northMag * Math.cos(decl);
        double az = normRad(Math.atan2(eTrue, nTrue));
        double alt = Math.asin(clamp(up));
        r.azTrueDeg = Math.toDegrees(az);
        r.altDeg = Math.toDegrees(alt);

        // 2. Julian Date & Local Sidereal Time (accounts for UTC time, date/season, and GPS longitude)
        double jd = utcMs / 86400000.0 + 2440587.5;
        double d = jd - 2451545.0;
        double t = d / 36525.0;
        double gmstDeg = 280.46061837 + 360.98564736629 * d + 0.000387933 * t * t - (t * t * t) / 38710000.0;
        double lst = Math.toRadians(normDeg(gmstDeg + lonDeg));
        r.jd = jd;
        r.lstDeg = Math.toDegrees(lst);

        // 3. Horizontal (az, alt) -> Equatorial of-date (RA, Dec)
        double lat = Math.toRadians(latDeg);
        double sinDec = Math.sin(alt) * Math.sin(lat) + Math.cos(alt) * Math.cos(lat) * Math.cos(az);
        double dec = Math.asin(clamp(sinDec));
        double ha = Math.atan2(-Math.cos(alt) * Math.sin(az), Math.sin(alt) * Math.cos(lat) - Math.cos(alt) * Math.sin(lat) * Math.cos(az));
        double ra = normRad(lst - ha);
        r.raDateDeg = Math.toDegrees(ra);
        r.decDateDeg = Math.toDegrees(dec);

        // 4. Precession: Equatorial of-date -> J2000.0 (Lieske 1979, transpose of P)
        double xDate = Math.cos(dec) * Math.cos(ra);
        double yDate = Math.cos(dec) * Math.sin(ra);
        double zDate = Math.sin(dec);
        double zeta = Math.toRadians((2306.2181 * t + 0.30188 * t * t + 0.017998 * t * t * t) / 3600.0);
        double z = Math.toRadians((2306.2181 * t + 1.09468 * t * t + 0.018203 * t * t * t) / 3600.0);
        double theta = Math.toRadians((2004.3109 * t - 0.42665 * t * t - 0.041833 * t * t * t) / 3600.0);

        double cz = Math.cos(z), sz = Math.sin(z), czeta = Math.cos(zeta), szeta = Math.sin(zeta), ct = Math.cos(theta), st = Math.sin(theta);
        double p11 = czeta * ct * cz - szeta * sz, p12 = -szeta * ct * cz - czeta * sz, p13 = -st * cz;
        double p21 = czeta * ct * sz + szeta * cz, p22 = -szeta * ct * sz + czeta * cz, p23 = -st * sz;
        double p31 = czeta * st, p32 = -szeta * st, p33 = ct;

        double x = p11 * xDate + p21 * yDate + p31 * zDate;
        double y = p12 * xDate + p22 * yDate + p32 * zDate;
        double z0 = p13 * xDate + p23 * yDate + p33 * zDate;
        double raJ2000 = normRad(Math.atan2(y, x));
        double decJ2000 = Math.asin(clamp(z0));
        r.raJ2000Deg = Math.toDegrees(raJ2000);
        r.decJ2000Deg = Math.toDegrees(decJ2000);
        r.precessionRaDeg = Math.toDegrees(signedRad(raJ2000 - ra));
        r.precessionDecDeg = Math.toDegrees(decJ2000 - dec);

        // 5. Equatorial J2000 -> Galactic (l, b) using IAU J2000 transformation matrix
        double gx = -0.0548755604 * x - 0.8734370902 * y - 0.4838350155 * z0;
        double gy = 0.4941094279 * x - 0.4448296300 * y + 0.7469822445 * z0;
        double gz = -0.8676661490 * x - 0.1980763734 * y + 0.4559837762 * z0;
        r.galLDeg = Math.toDegrees(normRad(Math.atan2(gy, gx)));
        r.galBDeg = Math.toDegrees(Math.asin(clamp(gz)));
        return r;
    }

    public static double clamp(double v) { return Math.max(-1.0, Math.min(1.0, v)); }
    public static double normRad(double rad) { rad %= 2.0 * Math.PI; return rad < 0 ? rad + 2.0 * Math.PI : rad; }
    public static double signedRad(double rad) { rad %= 2.0 * Math.PI; return rad > Math.PI ? rad - 2.0 * Math.PI : (rad < -Math.PI ? rad + 2.0 * Math.PI : rad); }
    public static double normDeg(double deg) { deg %= 360.0; return deg < 0 ? deg + 360.0 : deg; }
}
