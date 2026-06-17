module ui.animation;

import raylib;
import core.stdc.math : fabsf;

// --- Spring Anim ---
// Damped spring physics (ζ=0.85, ω=200)

struct SpringAnim {
    float current;
    float target;
    float velocity;
}

SpringAnim springCreate() {
    SpringAnim anim;
    anim.current = 0.0f;
    anim.target = 0.0f;
    anim.velocity = 0.0f;
    return anim;
}

void springSetTarget(SpringAnim* anim, float targetVal) {
    anim.target = targetVal;
}

void springUpdate(SpringAnim* anim, float dt) {
    float diff = anim.target - anim.current;
    if (fabsf(diff) < 0.001f && fabsf(anim.velocity) < 0.01f) {
        anim.current = anim.target;
        anim.velocity = 0.0f;
        return;
    }

    float tension = 200.0f;
    float damping = 0.85f * 2.0f * 14.1421356f; // approx 2*sqrt(tension)
    
    float force = (tension * diff) - (damping * anim.velocity);
    anim.velocity += force * dt;
    anim.current += anim.velocity * dt;
}

// --- Fade Anim ---

struct FadeAnim {
    float current;
    float target;
    float speed;
}

FadeAnim fadeCreate(float spd = 5.0f) {
    FadeAnim anim;
    anim.current = 0.0f;
    anim.target = 0.0f;
    anim.speed = spd;
    return anim;
}

void fadeSetTarget(FadeAnim* anim, float targetVal) {
    anim.target = targetVal;
}

void fadeUpdate(FadeAnim* anim, float dt) {
    float diff = anim.target - anim.current;
    if (fabsf(diff) < 0.001f) {
        anim.current = anim.target;
        return;
    }
    float step = anim.speed * dt;
    if (fabsf(diff) <= step) {
        anim.current = anim.target;
    } else {
        anim.current += (diff > 0.0f ? step : -step);
    }
}

// --- Slide Anim ---

struct SlideAnim {
    SpringAnim offset;
    FadeAnim opacity;
}

SlideAnim slideCreate() {
    SlideAnim anim;
    anim.offset = springCreate();
    anim.opacity = fadeCreate(5.0f);
    return anim;
}

void slideTriggerIn(SlideAnim* anim, float startOffset) {
    anim.offset.current = startOffset;
    anim.offset.target = 0.0f;
    anim.offset.velocity = 0.0f;
    
    anim.opacity.current = 0.0f;
    anim.opacity.target = 1.0f;
}

void slideTriggerOut(SlideAnim* anim, float endOffset) {
    anim.offset.target = endOffset;
    anim.opacity.target = 0.0f;
}

void slideUpdate(SlideAnim* anim, float dt) {
    springUpdate(&anim.offset, dt);
    fadeUpdate(&anim.opacity, dt);
}
