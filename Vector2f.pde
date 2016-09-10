public class Vector2f {

    public float x = 0;
    public float y = 0;

    public Vector2f() {

    }
    
    public Vector2f(float x, float y) {
        this.x = x;
        this.y = y;
    }

    public Vector2f(Vector2f other) {
        this.x = other.x;
        this.y = other.y;
    }

    public Vector2f(float angle) {
        angle = (float) Math.toRadians(angle);
        this.x = (float) Math.cos(angle);
        this.y = (float) Math.sin(angle);
    }

    public float getTheta() {
        return (float) Math.atan2(y, x);
    }

    public Vector2f scale(float scale) {
        this.x = x * scale;
        this.y = y * scale;
        return this;
    }

    public Vector2f set(float x, float y) {
        this.x = x;
        this.y = y;
        return this;
    }

    public Vector2f normalize() {
        float magnitude = (float) Math.sqrt((x * x) + (y * y));
        this.x = x / magnitude;
        this.y = y / magnitude;
        return this;
    }
    
       public Vector2f get(float[] t) {
        t[0] = this.x;
        t[1] = this.y;
        return this;
    }

}