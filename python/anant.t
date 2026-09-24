from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class MixRequest(BaseModel):
    grade: str                # M20, M25, M30
    target_volume_m3: float   # e.g., 1.0, 0.5
    plastic_type: str        # PET, HDPE, LDPE, PP, PVC, PS
    plastic_form: str        # Fibers, Flakes, Shredded, Pellets
    replacement_target: str  # fine_sand, coarse_agg, cement
    plastic_percentage: float
    fly_ash_percentage: float
    sodium_silicate_percentage: float

@app.post("/calculate-mix")
def calculate_mix(req: MixRequest):
    # डेंसिटी मैपिंग (kg/m3)
    densities = {"PET": 1380, "HDPE": 950, "LDPE": 920, "PP": 905, "PVC": 1350, "PS": 1050}
    p_density = densities.get(req.plastic_type, 1100)

    # IS 10262 बेसलाइन (kg/m3)
    base_data = {
        "M20": {"cement": 360, "water": 180, "fine": 680, "coarse": 1180},
        "M25": {"cement": 410, "water": 185, "fine": 650, "coarse": 1155},
        "M30": {"cement": 440, "water": 190, "fine": 630, "coarse": 1140}
    }.get(req.grade, {"cement": 410, "water": 185, "fine": 650, "coarse": 1155})

    vol = req.target_volume_m3
    raw_cement = base_data["cement"] * vol
    raw_water = base_data["water"] * vol
    raw_fine = base_data["fine"] * vol
    raw_coarse = base_data["coarse"] * vol

    # फ्लाई ऐश और सीमेंट
    fly_ash_kg = raw_cement * (req.fly_ash_percentage / 100.0)
    cement_kg = raw_cement - fly_ash_kg
    sodium_silicate_kg = (cement_kg + fly_ash_kg) * (req.sodium_silicate_percentage / 100.0)

    # प्लास्टिक वॉल्यूमेट्रिक रिप्लेसमेंट
    plastic_kg = 0.0
    fine_kg = raw_fine
    coarse_kg = raw_coarse

    if req.replacement_target == "fine_sand":
        replaced_fine = raw_fine * (req.plastic_percentage / 100.0)
        plastic_kg = (replaced_fine / 2650.0) * p_density
        fine_kg = raw_fine - replaced_fine
    else:
        replaced_coarse = raw_coarse * (req.plastic_percentage / 100.0)
        plastic_kg = (replaced_coarse / 2650.0) * p_density
        coarse_kg = raw_coarse - replaced_coarse

    # एआई प्रिडिक्शन और स्ट्रेंथ लॉजिक
    strength_verdict = "सुरक्षित (Safe Structural Use)"
    advisory = "मिश्रण का बॉन्ड और स्ट्रेंथ मानक सीमा के भीतर है।"
    
    if req.plastic_percentage > 15.0:
        strength_verdict = "चेतावनी: स्ट्रेंथ में गिरावट (Non-Structural / Paver Blocks Only)"
        advisory = f"{req.plastic_percentage}% प्लास्टिक से कंप्रेसिव स्ट्रेंथ 25-35% घट सकती है। सोडियम सिलिकेट की मात्रा 4% से ऊपर रखें।"
    elif req.replacement_target == "fine_sand" and req.plastic_form == "Fibers":
        advisory = "फाइबर फॉर्म डेजर्ट सैंड के साथ क्रैक रेजिस्टेंस और डक्टिलिटी को बहुत बेहतर बनाएगा।"

    return {
        "cement_kg": round(cement_kg, 2),
        "fly_ash_kg": round(fly_ash_kg, 2),
        "fine_sand_kg": round(fine_kg, 2),
        "coarse_agg_kg": round(coarse_kg, 2),
        "plastic_kg": round(plastic_kg, 2),
        "sodium_silicate_kg": round(sodium_silicate_kg, 2),
        "water_liters": round(raw_water, 2),
        "strength_verdict": strength_verdict,
        "ai_advisory": advisory
    }