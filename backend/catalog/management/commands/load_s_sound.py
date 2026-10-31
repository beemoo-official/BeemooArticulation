"""
Seed the database with all /s/ articulation content:
- 1 umbrella (clear-speech)
- 9 activities (levels 1-8 + flashcards)
- 30 stimuli
- 3 flashcard groups
- All screen records from the bundle JSON configs
"""
import json
from pathlib import Path

from django.core.management.base import BaseCommand
from catalog.models import Umbrella, Activity, Screen, Stimulus, FlashcardGroup, FlashcardOrder


# Path to the iOS bundle JSON configs
RESOURCES = Path(__file__).resolve().parents[5] / "BeemooArticulation" / "BeemooArticulation" / "Resources"

STIMULI = [
    # Initial S
    ("S-INI-01", "sun",      "initial", "BEEMOO_Initial_S_Sun.png",     "The sun is hot.",       "BEEMOO_Initial_S_Sun.png"),
    ("S-INI-02", "sock",     "initial", "BEEMOO_Initial_S_Sock.png",    "My sock is red.",       "BEEMOO_Initial_S_Sentence_02_My_Sock_Is_Red.png"),
    ("S-INI-03", "soup",     "initial", "BEEMOO_Initial_S_Soup.png",    "The soup is yummy.",    "BEEMOO_Initial_S_Sentence_03_The_Soup_Is_Yummy.png"),
    ("S-INI-04", "seal",     "initial", "BEEMOO_Initial_S_Seal.png",    "The seal is wet.",      "BEEMOO_Initial_S_Sentence_04_The_Seal_Is_Wet.png"),
    ("S-INI-05", "sit",      "initial", "BEEMOO_Initial_S_Sit.png",     "I like to sit.",        "BEEMOO_Initial_S_Sentence_05_I_Like_To_Sit.png"),
    ("S-INI-06", "soap",     "initial", "BEEMOO_Initial_S_Soap.png",    "The soap is pink.",     "BEEMOO_Initial_S_Sentence_06_The_Soap_Is_Pink.png"),
    ("S-INI-07", "sad",      "initial", "BEEMOO_Initial_S_Sad.png",     "I am sad.",             "BEEMOO_He_Is_Sad.png"),
    ("S-INI-08", "sip",      "initial", "BEEMOO_Initial_S_Sip.png",     "I sip my milk.",        "BEEMOO_Initial_S_Sentence_08_I_Sip_My_Milk.png"),
    ("S-INI-09", "sail",     "initial", "BEEMOO_Initial_S_Sail.png",    "I sail the boat.",      "BEEMOO_Initial_S_Sentence_09_I_Sail_The_Boat.png"),
    ("S-INI-10", "sack",     "initial", "BEEMOO_Initial_S_Sack.png",    "The sack is heavy.",    "BEEMOO_Initial_S_Sentence_10_The_Sack_Is_Heavy.png"),
    # Final S
    ("S-FIN-01", "bus",      "final",   "BEEMOO_Final_S_01_Bus.png",                "I ride the bus.",       "BEEMOO_Final_S_Sentence_01_I_Ride_The_Bus_No_Text.png"),
    ("S-FIN-02", "house",    "final",   "BEEMOO_Final_S_02_House.png",              "We live in a house.",   "BEEMOO_Final_S_Sentence_02_We_Live_In_A_House.png"),
    ("S-FIN-03", "mouse",    "final",   "BEEMOO_Final_S_REPLACEMENT_Mouse.png",     "I have a mouse.",       "BEEMOO_Final_S_Sentence_03_I_Have_A_Mouse.png"),
    ("S-FIN-04", "ice",      "final",   "BEEMOO_Final_S_04_Ice.png",                "I have ice.",           "BEEMOO_Final_S_Sentence_04_I_Have_Ice.png"),
    ("S-FIN-05", "face",     "final",   "BEEMOO_Final_S_REPLACEMENT_Face.png",      "I wash my face.",       "BEEMOO_Final_S_Sentence_05_I_Wash_My_Face.png"),
    ("S-FIN-06", "kiss",     "final",   "BEEMOO_Final_S_06_Kiss.png",               "Give me a kiss.",       "BEEMOO_Final_S_Sentence_06_Give_Me_A_Kiss.png"),
    ("S-FIN-07", "rice",     "final",   "BEEMOO_Final_S_07_Rice_REVISED.png",       "I eat rice.",           "BEEMOO_Final_S_Sentence_07_I_Eat_Rice.png"),
    ("S-FIN-08", "goose",    "final",   "BEEMOO_Final_S_08_Goose.png",              "I pet the goose.",      "BEEMOO_Final_S_Sentence_08_I_Pet_The_Goose.png"),
    ("S-FIN-09", "juice",    "final",   "BEEMOO_Final_S_REPLACEMENT_Juice.png",     "I drink juice.",        "BEEMOO_Final_S_Sentence_09_I_Drink_Juice.png"),
    ("S-FIN-10", "dress",    "final",   "BEEMOO_Final_S_REPLACEMENT_Dress.png",     "I love my dress!",      "BEEMOO_Final_S_Sentence_10_I_Love_My_Dress_Red_Hair.png"),
    # Medial S
    ("S-MED-01", "dinosaur", "medial",  "BEEMOO_Medial_S_Dinosaur.png",             "The dinosaur is big.",  "BEEMOO_Medial_S_Sentence_01_The_Dinosaur_Is_Big.png"),
    ("S-MED-02", "bicycle",  "medial",  "BEEMOO_Medial_S_Bicycle_Full.png",         "I ride my bicycle.",    "BEEMOO_Medial_S_Sentence_02_I_Ride_My_Bicycle.png"),
    ("S-MED-03", "messy",    "medial",  "BEEMOO_Medial_S_Messy_CLEAN.png",          "My room is messy.",     "BEEMOO_Medial_S_Sentence_03_My_Room_Is_Messy.png"),
    ("S-MED-04", "fossil",   "medial",  "BEEMOO_Medial_S_Fossil.png",               "I found a fossil.",     "BEEMOO_Medial_S_Sentence_04_I_Found_A_Fossil.png"),
    ("S-MED-05", "castle",   "medial",  "BEEMOO_Medial_S_Castle_FINAL.png",         "I made a castle.",      "BEEMOO_Medial_S_Sentence_05_I_Made_A_Castle.png"),
    ("S-MED-06", "whistle",  "medial",  "BEEMOO_Medial_S_Whistle_NEW.png",          "I blow the whistle.",   "BEEMOO_Medial_S_Sentence_06_I_Blow_The_Whistle_Black_Girl.png"),
    ("S-MED-07", "dresser",  "medial",  "BEEMOO_Medial_S_Dresser_REVISED.png",      "My dresser is brown.",  "BEEMOO_Medial_S_Sentence_07_My_Dresser_Is_Brown.png"),
    ("S-MED-08", "eraser",   "medial",  "BEEMOO_Medial_S_Eraser.png",               "I have an eraser.",     "BEEMOO_Medial_S_Sentence_08_I_Have_An_Eraser.png"),
    ("S-MED-09", "faucet",   "medial",  "BEEMOO_Medial_S_Faucet.png",               "I turn on the faucet.", "BEEMOO_Medial_S_Sentence_09_I_Turn_On_The_Faucet_Blond_Boy.png"),
    ("S-MED-10", "wrestle",  "medial",  "BEEMOO_Medial_S_Wrestle.png",              "I like to wrestle.",    "BEEMOO_Medial_S_Sentence_10_I_Like_To_Wrestle.png"),
]

UMBRELLA = {
    "key": "clear-speech",
    "title": "Clear Speech",
    "desc": "Practice making sounds so others can understand you.",
    "icon": "ico_speech.png",
    "tint": "#EEF7EA",
    "ink": "#3E9B4F",
    "sort_order": 0,
}

ACTIVITIES = [
    ("s-sound-level-1", "Make the S Sound",        "S1", 0),
    ("s-sound-level-2", "Hear the S Sound",        "S2", 1),
    ("s-sound-level-3", "Beginning S Words",        "S3", 2),
    ("s-sound-level-4", "Final S Words",            "S4", 3),
    ("s-sound-level-5", "Middle S Words",           "S5", 4),
    ("s-sound-level-6", "Beginning S Sentences",    "S6", 5),
    ("s-sound-level-7", "Final S Sentences",        "S7", 6),
    ("s-sound-level-8", "Middle S Sentences",       "S8", 7),
    ("s-sound-flashcards", "S Sound Flashcards",    "SF", 8),
]


class Command(BaseCommand):
    help = "Seed all /s/ articulation content"

    def handle(self, *args, **options):
        # Umbrella
        umbrella, _ = Umbrella.objects.update_or_create(
            key=UMBRELLA["key"], defaults=UMBRELLA
        )
        self.stdout.write(f"Umbrella: {umbrella}")

        # Stimuli
        for sid, word, pos, wimg, sent, simg in STIMULI:
            Stimulus.objects.update_or_create(
                stimulus_id=sid,
                defaults={
                    "target_word": word,
                    "target_position": pos,
                    "target_sound": "s",
                    "word_image": wimg,
                    "sentence_text": sent,
                    "sentence_image": simg,
                },
            )
        self.stdout.write(f"Stimuli: {len(STIMULI)} loaded")

        # Activities + screens from bundle JSON
        for aid, title, initials, order in ACTIVITIES:
            activity, _ = Activity.objects.update_or_create(
                activity_id=aid,
                defaults={
                    "title": title,
                    "umbrella": umbrella,
                    "orientation": "landscape",
                    "concepts": ["S"],
                    "status": "live",
                    "is_new": True,
                    "initials": initials,
                    "tint": "#3E9B4F",
                    "desc": f"Practice {title.lower()}",
                    "sort_order": order,
                    "version": 1,
                },
            )

            # Load screens from bundle JSON
            json_path = RESOURCES / f"{aid}.json"
            if json_path.exists():
                config = json.loads(json_path.read_text())
                Screen.objects.filter(activity=activity).delete()
                for s in config.get("screens", []):
                    n = s.pop("n")
                    stype = s.pop("type")
                    concept = s.pop("concept")
                    Screen.objects.create(
                        activity=activity,
                        n=n,
                        type=stype,
                        concept=concept,
                        payload=s,  # everything else goes in payload
                    )
                self.stdout.write(f"  {aid}: {len(config['screens'])} screens")
            else:
                self.stdout.write(self.style.WARNING(f"  {aid}: no JSON found at {json_path}"))

        # Flashcard groups
        for pos, title_pos in [("initial", "Beginning S"), ("final", "Final S"), ("medial", "Middle S")]:
            group, _ = FlashcardGroup.objects.update_or_create(
                slug=f"{pos}-s",
                defaults={
                    "title": title_pos,
                    "target_sound": "s",
                    "target_position": pos,
                },
            )
            FlashcardOrder.objects.filter(group=group).delete()
            stims = Stimulus.objects.filter(target_position=pos, target_sound="s").order_by("stimulus_id")
            for i, stim in enumerate(stims):
                FlashcardOrder.objects.create(group=group, stimulus=stim, position=i)
            self.stdout.write(f"  Flashcard group '{pos}-s': {stims.count()} stimuli")

        self.stdout.write(self.style.SUCCESS("Done!"))
