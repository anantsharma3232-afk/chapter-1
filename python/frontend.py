import streamlit as st
import requests

st.set_page_config(page_title="Eco-Concrete Mix Designer", layout="centered")

st.title("🏗️ Sustainable Concrete Mix Calculator")
st.write("FastAPI आधारित प्लास्टिक व फ्लाई-ऐश कंक्रीट मिक्स डिज़ाइन")

# इनपुट फ़ॉर्म
with st.form("mix_form"):
    grade = st.selectbox("कंक्रीट ग्रेड (Concrete Grade)", ["M20", "M25", "M30"])
    target_volume = st.number_input("लक्ष्य आयतन (Target Volume in m³)", min_value=0.1, value=1.0, step=0.1)
    
    col1, col2 = st.columns(2)
    with col1:
        plastic_type = st.selectbox("प्लास्टिक प्रकार (Plastic Type)", ["PET", "HDPE", "PP"])
        plastic_form = st.selectbox("प्लास्टिक रूप (Plastic Form)", ["fibers", "shredded", "pellets"])
    with col2:
        replacement_target = st.selectbox("रिप्लेसमेंट टारगेट", ["fine_sand", "coarse_aggregate"])
        plastic_percentage = st.slider("प्लास्टिक प्रतिशत (%)", min_value=0.0, max_value=20.0, value=5.0)

    fly_ash = st.slider("फ्लाई ऐश प्रतिशत (%)", min_value=0.0, max_value=30.0, value=10.0)
    sodium_silicate = st.slider("सोडियम सिलिकेट प्रतिशत (%)", min_value=0.0, max_value=10.0, value=2.0)

    submitted = st.form_submit_button("गणना करें (Calculate Mix)")

# जब यूज़र बटन दबाए
if submitted:
    payload = {
        "grade": grade,
        "target_volume_m3": target_volume,
        "plastic_type": plastic_type,
        "plastic_form": plastic_form,
        "replacement_target": replacement_target,
        "plastic_percentage": plastic_percentage,
        "fly_ash_percentage": fly_ash,
        "sodium_silicate_percentage": sodium_silicate
    }

    try:
        response = requests.post("http://127.0.0.1:8000/calculate-mix", json=payload)
        if response.status_code == 200:
            res_data = response.json()
            st.success("✅ गणना सफल रही!")
            st.json(res_data)
        else:
            st.error(f"एरर आया: {response.status_code}")
            st.write(response.text)
    except Exception as e:
        st.error("बैकएंड सर्वर चालू नहीं है! कृपया सुनिश्चित करें कि FastAPI (Uvicorn) चल रहा है।")