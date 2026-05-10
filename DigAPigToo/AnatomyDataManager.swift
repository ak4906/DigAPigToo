//
//  AnatomyDataManager.swift
//  DigAPigToo
//
//  Created by Alexander Knue on 5/8/26.
//

import Foundation
import Combine

class AnatomyDataManager: ObservableObject {
    @Published var categories: [AnatomyCategory] = []
    @Published var structures: [AnatomyStructure] = []
    @Published var traces: [TraceQuestion] = []
    @Published var fillBlanks: [FillBlankQuestion] = []
    @Published var diagramGroups: [DiagramGroup] = []

    static let shared = AnatomyDataManager()

    private init() {
        loadData()
    }

    private func loadData() {
        categories = createCategories()
        structures = createStructures()
        traces = createTraces()
        fillBlanks = createFillBlanks()
        diagramGroups = createDiagramGroups()
    }

    // MARK: - Diagram Groups
    // Add new reference photo groups here as you upload images to R2.
    // Naming convention: ref_[system]_[number].png
    // e.g. ref_arterial-system_1.png, ref_anatomical-planes_1.png
    private func createDiagramGroups() -> [DiagramGroup] {
        return [
            DiagramGroup(
                title: "Anatomical Planes",
                description: "Frontal, sagittal, and transverse planes through the fetal pig",
                systemImage: "square.split.2x2",
                images: [
                    ImageCDN.image("ref_planes_1.png", caption: "Anatomical Planes — Frontal, Sagittal & Transverse"),
                ]
            ),
            DiagramGroup(
                title: "Arterial System",
                description: "All major arteries branching from the aorta and heart",
                systemImage: "heart.fill",
                images: [
                    ImageCDN.image("ref_arterial-system_1.jpeg", caption: "Arterial System Overview"),
                ]
            ),
            DiagramGroup(
                title: "Venous System",
                description: "Major veins draining to the cranial and caudal vena cava",
                systemImage: "drop.fill",
                images: [
                    ImageCDN.image("ref_venous-system_1.jpeg", caption: "Venous System Overview"),
                    ImageCDN.image("ref_caudal-vena-cava_1.jpeg", caption: "Caudal Vena Cava & Tributaries"),
                ]
            ),
            // ── Add more groups below as you gather photos ──────────────────
        ]
    }
    
    // MARK: - Category Methods
    
    private func createCategories() -> [AnatomyCategory] {
        return [
            AnatomyCategory(name: "Anatomical Planes", description: "Body planes used for directional reference"),
            AnatomyCategory(name: "Directional Terminology", description: "Terms describing anatomical direction"),
            AnatomyCategory(name: "External", description: "External anatomical features"),
            AnatomyCategory(name: "Buccal Cavity", description: "Mouth and throat structures"),
            AnatomyCategory(name: "Upper Thoracic", description: "Upper chest structures"),
            AnatomyCategory(name: "Peritoneal Cavity", description: "Abdominal cavity"),
            AnatomyCategory(name: "Digestive System", description: "Gastrointestinal tract and organs"),
            AnatomyCategory(name: "Respiratory System", description: "Lungs and airway structures"),
            AnatomyCategory(name: "Circulatory System", description: "Heart, arteries, and veins"),
            AnatomyCategory(name: "Urinary System", description: "Kidney, bladder, and urinary structures"),
            AnatomyCategory(name: "Male Reproductive", description: "Male reproductive anatomy"),
            AnatomyCategory(name: "Female Reproductive", description: "Female reproductive anatomy"),
            AnatomyCategory(name: "Fetal Structures", description: "Embryological and fetal structures"),
            AnatomyCategory(name: "Adult Maternal Pig", description: "Maternal pig anatomy seen at the adult station"),
            AnatomyCategory(name: "Cow Eye", description: "Cow eye dissection structures"),
            AnatomyCategory(name: "Blood Histology", description: "Blood cells and components"),
            AnatomyCategory(name: "Vessel Histology", description: "Blood vessel tissue organization"),
            AnatomyCategory(name: "Respiratory Histology", description: "Respiratory tissue structure"),
            AnatomyCategory(name: "Gastrointestinal Histology", description: "Digestive tract tissue"),
            AnatomyCategory(name: "Liver Histology", description: "Hepatic tissue structure and organization"),
            AnatomyCategory(name: "Pancreas Histology", description: "Exocrine and endocrine pancreatic tissue"),
            AnatomyCategory(name: "Kidney Histology", description: "Renal tissue structure"),
            AnatomyCategory(name: "Reproductive Histology", description: "Gonadal and reproductive tissue"),
            AnatomyCategory(name: "Microscope", description: "Microscope components and parts"),
            AnatomyCategory(name: "Epithelial Types", description: "Epithelial cell classifications, locations, and functions")
        ]
    }
    
    // MARK: - Structure Methods
    
    private func createStructures() -> [AnatomyStructure] {
        let categories = self.categories
        var structures: [AnatomyStructure] = []
        
        // MARK: Anatomical Planes
        if let planesCat = categories.first(where: { $0.name == "Anatomical Planes" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: planesCat.id,
                    name: "Frontal Plane",
                    aliases: ["Coronal plane"],
                    function: "Divides body into dorsal and ventral portions",
                    commonConfusions: [],
                    examTips: ["Separates back from belly"],
                    images: [
                        ImageCDN.image("frontal-plane_gross_1.png"),
                    ]
                ),
                AnatomyStructure(
                    categoryId: planesCat.id,
                    name: "Sagittal Plane",
                    aliases: ["Median plane"],
                    function: "Divides body into left and right portions",
                    commonConfusions: [],
                    examTips: ["Important for head/neck dissections"],
                    images: [
                        ImageCDN.image("sagittal-plane_gross_1.png"),
                    ]
                ),
                AnatomyStructure(
                    categoryId: planesCat.id,
                    name: "Transverse Plane",
                    aliases: ["Horizontal plane"],
                    function: "Divides body into cranial and caudal parts",
                    commonConfusions: [],
                    examTips: ["Creates cross-sections through body regions"],
                    images: [
                        ImageCDN.image("transverse-plane_gross_1.png"),
                    ]
                ),
            ])
        }
        
        // MARK: Directional Terminology
        if let directionalCat = categories.first(where: { $0.name == "Directional Terminology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Ventral/Dorsal",
                    aliases: ["Belly/back"],
                    function: "Describes position relative to ventral (belly) or dorsal (back) surface",
                    commonConfusions: [],
                    examTips: ["Ventral = toward belly; Dorsal = toward back"],
                    images: [ImageCDN.image("dorsal-ventral_gross_1.png", caption: "Dorsal vs. Ventral")]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Cranial/Caudal",
                    aliases: ["Head/tail direction"],
                    function: "Describes position toward head or tail",
                    commonConfusions: [],
                    examTips: ["Cranial = toward head; Caudal = toward tail"],
                    images: [ImageCDN.image("cranial-caudal_gross_1.png", caption: "Cranial vs. Caudal")]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Rostral",
                    aliases: ["Toward snout"],
                    function: "Toward the snout/front",
                    commonConfusions: [],
                    examTips: ["Specific to head region"]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Anterior/Posterior",
                    aliases: ["Front/back"],
                    function: "Front and back directional references",
                    commonConfusions: [],
                    examTips: ["More commonly used in human anatomy"]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Superior/Inferior",
                    aliases: ["Top/bottom"],
                    function: "Upper and lower directional references",
                    commonConfusions: [],
                    examTips: ["Less applicable to quadrupeds"]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Distal/Proximal",
                    aliases: ["Far/near"],
                    function: "Far from and near to a reference point",
                    commonConfusions: [],
                    examTips: ["Useful for limbs and vessels"],
                    images: [ImageCDN.image("proximal-distal_gross_1.png", caption: "Proximal vs. Distal")]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Lateral/Medial",
                    aliases: ["Side/middle"],
                    function: "Toward the side or toward the midline",
                    commonConfusions: [],
                    examTips: ["Lateral = toward side; Medial = toward midline"]
                ),
                AnatomyStructure(
                    categoryId: directionalCat.id,
                    name: "Superficial",
                    aliases: ["Surface"],
                    function: "Closer to the surface",
                    commonConfusions: [],
                    examTips: ["Opposite of deep"]
                ),
            ])
        }
        
        // MARK: External
        if let externalCat = categories.first(where: { $0.name == "External" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Rostral Plate",
                    aliases: ["Snout disk", "Porcine snout"],
                    function: "Used for rooting; searching through soil for food. Highly touch-sensitive.",
                    commonConfusions: [],
                    examTips: ["Snout disk at the very rostral end of pig containing nostril openings"],
                    histology: "Specialized integument; protective stratified squamous epithelium with sensory specialization",
                    connections: "Contains external nostrils; incorporates fleshy lips",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "External Nostril",
                    aliases: ["External naris", "Nares"],
                    function: "External respiratory openings; allow airflow into nasal cavity; olfaction; warming/humidification/filtering of air",
                    commonConfusions: [],
                    examTips: ["Two openings at tip of snout inside rostral plate"],
                    images: [ImageCDN.image("external-nostril_gross_1.jpeg", caption: "External Nostril")],
                    histology: "Continuous with external skin",
                    connections: "External nostril → nasal cavity → conchae → nasal pharynx → larynx/trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Auricle",
                    aliases: ["Pinna", "External ear"],
                    function: "Collects sound waves and directs them into the external acoustic meatus",
                    commonConfusions: [],
                    examTips: ["Look for obvious external ear flap on lateral head"],
                    histology: "Flexible external ear flap; supported by connective tissue/cartilage and covered by skin",
                    connections: "Auricle → external acoustic meatus → tympanic membrane",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "External Acoustic Meatus",
                    aliases: ["Ear canal", "Acoustic canal"],
                    function: "Conducts sound waves from auricle toward eardrum",
                    commonConfusions: [],
                    examTips: ["Opening/tunnel at base of auricle"],
                    histology: "Continuous with external skin; typically stratified squamous epithelium",
                    connections: "Auricle → external acoustic meatus → tympanic membrane",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Eyelid",
                    aliases: ["Palpebra"],
                    function: "Protects eyeball; maintains moist surface for eye function",
                    commonConfusions: ["In fetal pigs, eyelids may be fused"],
                    examTips: ["On fetal pigs, eyelids can be closed/fused. Make small incision near rostral corner to open"],
                    histology: "Stratified protective surface",
                    connections: "Eyelid covers eye; when opened reveals nictitating membrane",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Nictitating Membrane",
                    aliases: ["Third eyelid"],
                    function: "In pigs, moves across eyeball to distribute tears",
                    commonConfusions: ["Human equivalent is semilunar fold (doesn't move)"],
                    examTips: ["Look for it after carefully opening fused eyelids near rostral/inner eye corner"],
                    histology: "Thin movable membrane",
                    connections: "Associated with eyeball and eyelids",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Knee",
                    aliases: ["Stifle"],
                    function: "Major flexion-extension joint for locomotion",
                    commonConfusions: ["Do not confuse with ankle; pigs are ungulates with elongated distal limbs"],
                    examTips: ["Joint between femur and lower hindlimb"],
                    histology: "Joint structure",
                    connections: "Proximal to ankle",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Ankle",
                    aliases: ["Tarsus", "Hock"],
                    function: "Supports locomotion; force transfer; hoof-bearing stance",
                    commonConfusions: ["Often mistaken for knee because pig's heel is elevated off ground"],
                    examTips: ["Distal hindlimb joint; in pigs, ankle/wrist elevated, not plantigrade like humans"],
                    histology: "Joint structure",
                    connections: "Distal to knee; supports hoof",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Wrist",
                    aliases: ["Carpus"],
                    function: "Provides distal forelimb mobility while maintaining elevated limb posture",
                    commonConfusions: [],
                    examTips: ["Distal forelimb joint; held above ground in ungulates"],
                    histology: "Joint structure",
                    connections: "Distal forelimb joint",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Elbow",
                    aliases: ["Olecranon"],
                    function: "Allows forelimb flexion and extension",
                    commonConfusions: [],
                    examTips: ["Forelimb joint between upper and lower forelimb"],
                    histology: "Joint structure",
                    connections: "Proximal forelimb joint",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Hoof",
                    aliases: ["Unguis"],
                    function: "Protects distal digits during locomotion, weight bearing, contact with hard surfaces",
                    commonConfusions: ["Similar to fingernails/toenails"],
                    examTips: ["Keratinized distal covering of pig digits"],
                    histology: "Keratinized covering",
                    connections: "Covers distal digits",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "2nd, 3rd, 4th, 5th Digits",
                    aliases: ["Toes", "Digits"],
                    function: "Weight-bearing and locomotion",
                    commonConfusions: ["Pig digits correspond to human digits 2-5; digit 1 is absent"],
                    examTips: ["Digits 3 and 4 largest and primary weight-bearing; digits 2 and 5 smaller"],
                    histology: "Skeletal elements and integument",
                    connections: "Supported by limb skeletal system",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Mammary Papilla",
                    aliases: ["Nipple", "Teat"],
                    function: "In adult females, serve as openings for milk delivery; allow offspring nursing",
                    commonConfusions: ["Both male and female fetal pigs possess them"],
                    examTips: ["Small nipple-like projections in rows along ventral trunk surface"],
                    histology: "External projection; internal connection to lactiferous ducts. External surface: stratified squamous; ducts: cuboidal epithelium",
                    connections: "Connected internally to mammary gland ducts, glandular tissue, connective tissue, blood vessels",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Umbilical Cord",
                    aliases: ["Umbilicus"],
                    function: "Connects fetus to placenta; contains vessels for nutrient transport, gas exchange, waste transport",
                    commonConfusions: [],
                    examTips: ["Attaches to ventral abdominal surface"],
                    histology: "Contains umbilical vessels protected by Wharton's jelly",
                    connections: "Fetal → placenta; contains umbilical vein, two umbilical arteries, allantoic stalk",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Umbilical Vein",
                    aliases: ["Umbilical venous trunk"],
                    function: "Carries oxygenated blood and nutrients FROM placenta TO fetus",
                    commonConfusions: ["Single large vessel; different from paired umbilical arteries"],
                    examTips: ["Single large thin-walled vessel within umbilical cord"],
                    histology: "Thin-walled vessel with simple squamous endothelium (simple squamous epithelium)",
                    connections: "Placenta → umbilical vein → ductus venosus → caudal vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Umbilical Arteries",
                    aliases: ["Umbilical arterial trunks"],
                    function: "Carry deoxygenated blood and metabolic wastes FROM fetus TO placenta",
                    commonConfusions: ["Two thick-walled vessels; opposite of what intuition suggests"],
                    examTips: ["Two thick-walled paired vessels; arteries have thicker walls than veins"],
                    histology: "Thick-walled with smooth muscle; simple squamous endothelium (simple squamous epithelium)",
                    connections: "Fetus → umbilical arteries → placenta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Allantoic Stalk",
                    aliases: ["Urachus"],
                    function: "Embryologically associated with fetal urine handling; in pigs, allantois develops extensively",
                    commonConfusions: ["Hard cord-like structure between/beneath umbilical arteries"],
                    examTips: ["Hard cord-like structure within umbilical cord"],
                    histology: "Connective tissue stalk",
                    connections: "Fetal bladder ↔ allantoic sac",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Preputial Orifice",
                    aliases: ["Male urogenital opening"],
                    function: "Shared external opening for urinary and reproductive systems",
                    commonConfusions: ["Located just caudal to umbilical cord; easy to confuse with female opening"],
                    examTips: ["Male opening more cranial than female opening"],
                    histology: "Transitions between external protective epithelium and urinary/reproductive mucosa",
                    connections: "Urethra → penis → preputial orifice",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Scrotum",
                    aliases: ["Scrotal sac"],
                    function: "In mature males, houses testes; participates in temperature regulation for spermatogenesis",
                    commonConfusions: [],
                    examTips: ["Sac-like structure caudal to hind limbs, ventral to tail"],
                    histology: "External: protective stratified squamous epithelium; internal: connective tissue and smooth muscle",
                    connections: "Contains testicular structures",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Anus",
                    aliases: ["Anal orifice"],
                    function: "Terminal opening for elimination of feces",
                    commonConfusions: [],
                    examTips: ["Located immediately ventral to tail; present in both sexes"],
                    histology: "Protective stratified squamous epithelium at terminal digestive tract",
                    connections: "Rectum → anal canal → anus",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Genital Papilla",
                    aliases: ["Female external genitalia"],
                    function: "Part of external female reproductive anatomy",
                    commonConfusions: ["Spike-like projection; contains clitoris internally"],
                    examTips: ["Located ventral to anus, near urogenital orifice; important for sex identification"],
                    histology: "Skin-covered projection with underlying connective tissue",
                    connections: "Associated with vulva, urogenital opening, reproductive tract",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: externalCat.id,
                    name: "Urogenital Orifice",
                    aliases: ["Female urogenital opening"],
                    function: "Common opening for urinary tract and vagina",
                    commonConfusions: ["Located ventral to anus; different from male opening"],
                    examTips: ["Near anus, associated with genital papilla in females"],
                    histology: "Transitions between external protective epithelium and reproductive/urinary mucosa",
                    connections: "Urethra + vagina → urogenital orifice",
                    highYield: false
                ),
            ])
        }
        
        // MARK: Digestive System
        if let digestiveCat = categories.first(where: { $0.name == "Digestive System" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Pyloric Sphincter",
                    aliases: ["Pylorus", "Pyloric valve"],
                    function: "Thickened ring of circular smooth muscle at the stomach–duodenum junction; controls the rate of gastric emptying by opening and closing to meter chyme into the duodenum",
                    commonConfusions: ["Pyloric sphincter vs pyloric antrum: the antrum is the stomach region just before the sphincter; the sphincter is the muscular valve itself", "Pyloric sphincter vs cardiac sphincter (cardia): cardiac sphincter is at the esophagus–stomach junction; pyloric is at stomach–duodenum"],
                    examTips: ["Practical ID: narrow thickened muscular ring at the exit of the stomach where it meets the duodenum", "Smooth muscle — involuntary control", "KEY FUNCTION: controlled valve preventing uncontrolled chyme passage"],
                    histology: "Greatly thickened circular smooth muscle layer; mucosa continues as simple columnar epithelium; pyloric glands on gastric side",
                    connections: "Stomach (pyloric antrum) → pyloric sphincter → duodenum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Duodenum",
                    aliases: ["First part of small intestine", "C-loop", "Duodenal loop"],
                    function: "First segment of small intestine; receives acidic chyme from stomach plus bile (via common bile duct) and pancreatic enzymes (via pancreatic duct and accessory pancreatic duct); site of major chemical digestion and beginning of absorption",
                    commonConfusions: ["Duodenum receives bile AND pancreatic enzymes — the accessory pancreatic duct empties directly into the duodenum (students commonly forget this)", "Duodenum vs jejunum on histology: Brunner's glands in the SUBMUCOSA = duodenum — the single most reliable identifier"],
                    examTips: ["Practical ID: C-shaped loop of intestine immediately after the pyloric sphincter", "Villi + Brunner's glands = duodenum", "KEY: accessory pancreatic duct empties here in addition to common bile duct"],
                    histology: "Simple columnar epithelium with villi; BRUNNER'S GLANDS in submucosa (alkaline mucus, acid neutralization) — distinguishing feature from rest of small intestine",
                    connections: "Pyloric sphincter → duodenum → jejunum; receives common bile duct + accessory pancreatic duct at hepatopancreatic ampulla",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Jejuno-ileum",
                    aliases: ["Jejunum", "Ileum", "Small intestine (pig)", "Jejunoileum"],
                    function: "Long coiled small intestine; primary site of nutrient absorption (amino acids, fatty acids, sugars, vitamins, minerals); ileum specifically absorbs vitamin B12, bile salts, and hosts Peyer's patches for immune surveillance",
                    commonConfusions: ["In pigs, the jejunum and ileum are not clearly demarcated and are called 'jejuno-ileum' as a unit", "Jejuno-ileum vs large intestine: small intestine has VILLI; large intestine does NOT — this is the #1 histological distinguishing feature", "Ileum vs jejunum histology: ileum has Peyer's patches in submucosa; jejunum does not"],
                    examTips: ["Practical ID: long coiled loops of intestine; narrower diameter than large intestine", "Villi present — this is small intestine", "Ileum portion: Peyer's patches = lymphoid aggregates visible in submucosa"],
                    histology: "Simple columnar epithelium with enterocytes (microvilli brush border), goblet cells, and villi; ileum portion has Peyer's patches (lymphoid aggregates in submucosa/mucosa)",
                    connections: "Duodenum → jejuno-ileum → caecum (at ileocaecal junction); suspended by intestinal mesentery",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Caecum",
                    aliases: ["Cecum", "Blind pouch", "Ileocaecal junction"],
                    function: "Blind-ended pouch at the junction of small and large intestine; in pigs, site of microbial fermentation, water absorption, and transitional digestive processing",
                    commonConfusions: ["Caecum is LARGE INTESTINE — no villi, increasing goblet cells", "Human appendix is a vestigial outgrowth of the caecum; pigs do not have a distinct appendix"],
                    examTips: ["Practical ID: blind pouch where jejuno-ileum meets the large intestine", "Larger diameter than small intestine; no villi"],
                    histology: "Simple columnar epithelium, reduced villi (transitional) → absent, increasing goblet cells; crypts of Lieberkühn; large intestine pattern",
                    connections: "Jejuno-ileum → ileocaecal junction → caecum → spiral colon",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Spiral Colon",
                    aliases: ["Pig colon", "Coiled large intestine"],
                    function: "Pig-specific coiled large intestine segment; major site of water absorption and fecal consolidation; the characteristic spiral arrangement is unique to pigs and some other mammals",
                    commonConfusions: ["Spiral colon is pig-specific — humans do not have this structure", "Spiral colon vs small intestine: NO villi + many goblet cells = large intestine/spiral colon"],
                    examTips: ["Practical ID: tightly coiled large intestinal structure, characteristic of pigs", "No villi + abundant goblet cells on histology", "KEY PIG ANATOMY: the spiral colon is a defining pig-specific structure"],
                    histology: "Simple columnar epithelium, NO villi, abundant goblet cells, crypts of Lieberkühn; large intestine pattern",
                    connections: "Caecum → spiral colon → transverse colon",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Rectum",
                    aliases: ["Terminal large intestine", "Pelvic colon"],
                    function: "Terminal portion of the large intestine within the pelvic cavity; stores feces and forms the defecation pathway; transitions from simple columnar to stratified squamous epithelium approaching the anus",
                    commonConfusions: ["Rectum is INSIDE the pelvis — it is the pelvic portion of the large intestine", "The rectum transitions to stratified squamous near the anal canal — this epithelial shift is testable"],
                    examTips: ["Practical ID: terminal segment of large intestine running into the pelvis", "Proximally: simple columnar + goblet cells; distally: transitions to stratified squamous near anus", "The transition from columnar to squamous protects against abrasion"],
                    histology: "Proximal: simple columnar epithelium with goblet cells, crypts; distal: gradual transition to stratified squamous epithelium approaching anal canal",
                    connections: "Descending colon → rectum (enters pelvis) → anal canal → anus",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Pancreas",
                    aliases: ["Pancreatic gland", "Exocrine/endocrine pancreas"],
                    function: "Dual-function gland: EXOCRINE — secretes digestive enzymes (trypsinogen, chymotrypsinogen, lipase, amylase) via pancreatic duct into duodenum; ENDOCRINE — secretes insulin (from β cells) and glucagon (from α cells) into blood via islets of Langerhans",
                    commonConfusions: ["CRITICAL TRACE: the ACCESSORY pancreatic duct empties DIRECTLY into the duodenum — students commonly forget this and only trace via the common bile duct", "Exocrine (acinar cells → ducts → duodenum) vs endocrine (islets of Langerhans → bloodstream) — two completely separate secretion routes"],
                    examTips: ["Practical ID: diffuse, lobulated glandular tissue adherent to the duodenal loop and near the stomach", "EXAM-CRITICAL: accessory pancreatic duct → duodenum directly (in addition to main pancreatic duct via common bile duct area)", "Acinar cells = exocrine enzyme producers; islets of Langerhans = endocrine hormone producers"],
                    histology: "Acinar cells (enzyme-secreting, zymogen granules) arranged around central ducts; islets of Langerhans scattered throughout (lighter staining endocrine clusters with α and β cells)",
                    connections: "Exocrine: acini → pancreatic ducts → duodenum; endocrine: islets → blood; sits adjacent to duodenum and caudal to stomach",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Gallbladder",
                    aliases: ["Bile storage sac", "Vesica biliaris"],
                    function: "Stores and concentrates bile produced by the liver; releases bile into the duodenum via the cystic duct → common bile duct in response to CCK (cholecystokinin) when dietary fat enters the small intestine",
                    commonConfusions: ["Gallbladder stores bile; liver PRODUCES bile — these are two different steps", "Bile flow path: liver → hepatic duct → (can go to gallbladder via cystic duct for storage) → cystic duct → common bile duct → duodenum"],
                    examTips: ["Practical ID: greenish sac on the underside/visceral surface of the liver", "Simple columnar epithelium inside — optimized for absorption/secretion during concentration"],
                    histology: "Simple columnar epithelium (tall, for absorptive concentration of bile); folded mucosa; smooth muscle wall for bile expulsion; no submucosa",
                    connections: "Liver (hepatic duct) → cystic duct → gallbladder; gallbladder → cystic duct → common bile duct → duodenum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Right Medial Lobe of Liver",
                    aliases: ["Right medial hepatic lobe", "Medial right lobe"],
                    function: "One of the four major liver lobes (right medial, left medial, right lateral, left lateral); performs all liver functions — metabolism, detoxification, bile production, glycogen storage, plasma protein synthesis, urea production",
                    commonConfusions: ["Pig liver has FIVE lobes: right medial, left medial, right lateral, left lateral, and caudate — not two like in simplified diagrams", "Right medial lobe is one of the central lobes visible ventrally on the liver"],
                    examTips: ["Practical ID: central liver lobe visible from the ventral surface, on the right side of midline", "The two medial lobes are the most prominently visible from the ventral aspect"],
                    histology: "Hepatocytes in lobules, liver sinusoids, portal triads at lobule periphery, central veins at lobule centers — same as all liver",
                    connections: "Part of liver mass; shares portal blood supply and hepatic venous drainage with other lobes; bile flows to hepatic ducts → common bile duct → duodenum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Left Medial Lobe of Liver",
                    aliases: ["Left medial hepatic lobe", "Medial left lobe"],
                    function: "One of the four major liver lobes; performs all standard liver functions in the same manner as the right medial lobe",
                    commonConfusions: ["Left medial vs left lateral: medial lobes are the more central/midline lobes; lateral lobes are the more peripheral/body-wall lobes", "Both medial lobes are visible ventrally and are histologically identical"],
                    examTips: ["Practical ID: central liver lobe visible from the ventral surface, on the left side of midline", "Mirror image of right medial lobe anatomically; identical histologically"],
                    histology: "Same as all liver: hepatocytes, sinusoids, portal triads, central veins",
                    connections: "Part of liver mass; drains to hepatic ducts and ultimately common bile duct",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Right Lateral Lobe of Liver",
                    aliases: ["Right lateral hepatic lobe", "Lateral right lobe"],
                    function: "More lateral lobe of the right liver; participates in all liver metabolic and secretory functions",
                    commonConfusions: ["Right lateral lobe is positioned more toward the right body wall compared to the right medial lobe", "May be partially obscured by right medial lobe when viewing from ventral surface"],
                    examTips: ["Practical ID: outer right liver lobe, positioned laterally toward the right body wall", "Histologically identical to all other liver lobes"],
                    histology: "Hepatocytes in lobules, liver sinusoids, portal triads, central veins — same as all liver",
                    connections: "Part of liver mass; portal blood supply shared with other lobes; bile drains to hepatic duct system",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Left Lateral Lobe of Liver",
                    aliases: ["Left lateral hepatic lobe", "Lateral left lobe"],
                    function: "More lateral lobe of the left liver; participates in all liver metabolic and secretory functions",
                    commonConfusions: ["Left lateral lobe extends more toward the left body wall; the left lateral lobe is often the largest lobe of the pig liver", "Students sometimes confuse the left lateral lobe with the spleen — spleen is darker and more elongated, positioned caudal to the liver"],
                    examTips: ["Practical ID: outermost left liver lobe, positioned laterally; often the largest single liver lobe in pigs", "Histologically identical to all other liver lobes"],
                    histology: "Hepatocytes in lobules, liver sinusoids, portal triads, central veins — same as all liver",
                    connections: "Part of liver mass; portal blood supply; bile drains to hepatic duct system",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Hepatic Ducts",
                    aliases: ["Bile ducts", "Hepatic duct", "Right and left hepatic ducts"],
                    function: "Carries bile from the liver toward the gallbladder and duodenum; the right and left hepatic ducts merge into the common hepatic duct, which then joins the cystic duct to form the common bile duct",
                    commonConfusions: ["Hepatic duct (from liver) + cystic duct (from gallbladder) = common bile duct; students often blur these three duct names", "Hepatic ducts carry bile FROM the liver; they are part of the bile OUTFLOW pathway"],
                    examTips: ["Trace: liver → hepatic duct → (joins cystic duct) → common bile duct → duodenum", "Or: liver → hepatic duct → cystic duct → gallbladder (for storage), then gallbladder → cystic duct → common bile duct → duodenum when needed"],
                    histology: "Simple columnar to cuboidal epithelium lining; surrounded by connective tissue; bile ducts are components of the portal triad in liver lobules",
                    connections: "Originates from bile canaliculi in liver lobules → bile ductules → hepatic ducts → common bile duct → ampulla of Vater → duodenum",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Caudate Lobe of Liver",
                    aliases: ["Caudate lobe", "Lobus caudatus"],
                    function: "The caudate lobe is the distinct fifth lobe of the fetal pig liver, located on the dorsal/caudal surface, partially wrapping around the caudal vena cava; participates in all standard liver functions — metabolism, detoxification, bile production, glycogen storage, plasma protein synthesis, and urea production",
                    commonConfusions: ["The fetal pig liver has FIVE named lobes: right medial, left medial, right lateral, left lateral, and caudate — the caudate is separately named and testable, not just part of 'liver lobes'", "The caudate lobe is smaller and positioned differently (caudodorsal) compared to the other four lobes"],
                    examTips: ["Practical ID: look on the dorsal/posterior surface of the liver — the caudate lobe is the distinct smaller lobe wrapping around/near the caudal vena cava", "On the practical, the five liver lobes may each be separately labeled — don't lump the caudate with 'liver lobes'", "The caudate lobe is histologically identical to other lobes (hepatocytes, sinusoids, portal triads, central veins) — it's distinguished anatomically, not histologically"],
                    histology: "Same as all liver: hepatocytes arranged in lobules, liver sinusoids (discontinuous capillaries), portal triads at lobule periphery (portal vein branch + hepatic artery branch + bile duct), central vein at lobule center",
                    connections: "Located on dorsal/caudal liver surface; closely associated with caudal vena cava and portal vein; shares blood supply and bile drainage with other liver lobes via the common hepatic duct system",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Mesentery",
                    aliases: ["Intestinal central mesentery", "Peritoneal support"],
                    function: "Double fold of peritoneum suspending the intestines from the dorsal body wall; carries blood vessels, lymphatics, and nerves to the gut",
                    commonConfusions: ["Not to be confused with the broad ligament (which suspends reproductive organs); the mesentery specifically suspends the small intestine"],
                    examTips: ["Practical ID: fan-like sheet of tissue connecting intestines to the dorsal wall, visible when intestines are reflected", "Contains the mesenteric arteries and veins running toward the intestinal wall"],
                    images: [ImageCDN.image("mesentery_gross_1.jpeg", caption: "Mesentery")],
                    histology: "Simple squamous mesothelium (peritoneum) covering loose connective tissue with blood vessels",
                    connections: "Attaches to dorsal body wall; contains cranial/caudal mesenteric arteries and veins; surrounds jejuno-ileum and much of colon",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Common Bile Duct",
                    aliases: ["Bile duct", "Ductus choledochus"],
                    function: "Carries bile from the hepatic and cystic duct junction into the duodenum; bile emulsifies dietary fats for lipase digestion",
                    commonConfusions: ["Common bile duct = hepatic duct + cystic duct combined; the cystic duct connects specifically from the gallbladder", "Bile flows from liver → hepatic duct → common bile duct → duodenum; or liver → hepatic duct → cystic duct → gallbladder (stored), then gallbladder → cystic duct → common bile duct → duodenum when needed"],
                    examTips: ["Practical ID: duct running from liver/gallbladder region toward the duodenum", "Opens into the duodenum at the hepatopancreatic ampulla (ampulla of Vater)", "On the practical, look for a duct associated with the gallbladder and hepatic ducts leading toward the small intestine"],
                    histology: "Simple columnar epithelium lining; surrounded by fibromuscular wall",
                    connections: "Hepatic duct (from liver) + cystic duct (from gallbladder) → common bile duct → duodenum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Cystic Duct",
                    aliases: ["Gallbladder duct"],
                    function: "Connects the gallbladder to the bile duct system; allows bile to flow in (storage) or out (release into common bile duct) of the gallbladder",
                    commonConfusions: ["Cystic duct ≠ common bile duct; the cystic duct is the short duct specifically from the gallbladder that joins the hepatic duct to FORM the common bile duct"],
                    examTips: ["Practical ID: short duct attached directly to the gallbladder, joining the hepatic duct", "Removal of the gallbladder (cholecystectomy) includes removal of the cystic duct"],
                    histology: "Simple columnar epithelium with spiral folds (valves of Heister) that regulate bile flow",
                    connections: "Gallbladder → cystic duct → joins hepatic duct → common bile duct → duodenum",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Transverse Colon",
                    aliases: ["Colon transversum"],
                    function: "Segment of large intestine running transversely across the abdomen after the spiral colon; continues water absorption and movement of fecal material toward the descending colon",
                    commonConfusions: ["In pigs, the large intestine coil arrangement differs from humans; the spiral colon is a pig-specific coiling before the transverse and descending segments", "The transverse colon is caudal to the spiral colon in pigs"],
                    examTips: ["Practical ID: colon segment running transversely across the mid-abdomen, leading from the spiral colon toward the descending colon", "No villi + abundant goblet cells = all large intestine histology, including transverse colon"],
                    histology: "Simple columnar epithelium, abundant goblet cells, no villi; crypts of Lieberkühn present; three-layered muscularis",
                    connections: "Receives from spiral colon; leads into descending colon; lies along dorsal transverse abdomen",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: digestiveCat.id,
                    name: "Descending Colon",
                    aliases: ["Colon descendens"],
                    function: "Caudal segment of the colon carrying fecal material from the transverse colon toward the rectum; final water absorption and fecal compaction",
                    commonConfusions: ["Descending colon leads into the rectum; the rectum is the terminal segment inside the pelvic cavity"],
                    examTips: ["Practical ID: colon running caudally from the transverse colon toward the pelvis/rectum", "Along with transverse colon, histologically identical to other large intestine — no villi, high goblet cell density"],
                    histology: "Same as all large intestine: simple columnar epithelium, abundant goblet cells, crypts of Lieberkühn, no villi, smooth muscle layers",
                    connections: "Receives from transverse colon; leads into rectum within the pelvic cavity",
                    highYield: false
                ),
            ])
        }
        
        // MARK: Respiratory System (expanded)
        if let respiratoryCat = categories.first(where: { $0.name == "Respiratory System" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Bronchi",
                    aliases: ["Bronchial tubes"],
                    function: "Conducts air from trachea to lungs",
                    examTips: ["Right and left bronchi branch from trachea"]
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Bronchioles",
                    aliases: ["Small bronchi"],
                    function: "Smallest branches of bronchial tree",
                    examTips: ["Connect bronchi to alveoli"]
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Cranial Lobe of Right Lung",
                    aliases: ["Right cranial lobe", "Right apical lobe"],
                    function: "Most cranial/anterior lobe of the right lung; first lobe visible when thoracic cavity is opened",
                    commonConfusions: ["Right lung has 4 lobes (cranial, middle, caudal, accessory); left lung has only 2 (cranial, caudal) — asymmetry is testable", "Cranial lobe of right vs left: right cranial lobe is larger and more prominent"],
                    examTips: ["Right lung = 4 lobes: cranial, middle, caudal, accessory", "Cranial lobe = most anterior, toward the head end of the lung"],
                    connections: "Part of right lung; supplied by right cranial lobar bronchus and branch of right pulmonary artery",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Cranial Lobe of Left Lung",
                    aliases: ["Left cranial lobe", "Left apical lobe"],
                    function: "Most cranial lobe of the left lung; the left lung is smaller than right due to cardiac notch accommodating the heart",
                    commonConfusions: ["Left lung has only 2 lobes (cranial + caudal) — NO middle lobe, NO accessory lobe", "The cardiac notch is on the left lung — the heart sits in this space"],
                    examTips: ["Left lung = 2 lobes only: cranial and caudal", "KEY: left lung smaller than right because heart displaces it leftward"],
                    connections: "Part of left lung; left cranial lobar bronchus; left pulmonary artery branch",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Middle Lobe of Right Lung",
                    aliases: ["Right middle lobe", "Medial lobe of right lung", "Right medial lobe"],
                    function: "Middle lobe of the right lung, situated between the cranial and caudal lobes; present only on the right side",
                    commonConfusions: ["Middle lobe exists ONLY on the right — the left lung has no middle lobe", "Students often forget the middle lobe exists or assign it to the left lung"],
                    examTips: ["RIGHT only: cranial + middle + caudal + accessory = 4 lobes", "Middle lobe is smaller than cranial and caudal lobes"],
                    connections: "Part of right lung between cranial and caudal lobes; right middle lobar bronchus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Accessory Lobe of Right Lung",
                    aliases: ["Right accessory lobe", "Azygos lobe", "Infracardiac lobe"],
                    function: "Small additional lobe of the right lung; lies medially near the heart and caudal vena cava; present only in pigs and some other mammals",
                    commonConfusions: ["Accessory lobe = RIGHT lung only — not present on left", "May be confused with the thymus or a lymph node if not traced to the right bronchial tree"],
                    examTips: ["KEY ID: small lobe medial to the caudal vena cava on the right side = accessory lobe", "Only on right lung — if you see it, you know you're on the right side"],
                    connections: "Part of right lung; medial position near caudal vena cava; right accessory lobar bronchus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Caudal Lobe of Right Lung",
                    aliases: ["Right caudal lobe", "Right diaphragmatic lobe"],
                    function: "Largest lobe of the right lung; lies against the diaphragm caudally",
                    commonConfusions: ["Both lungs have a caudal lobe — but the right caudal lobe is larger than the left caudal lobe"],
                    examTips: ["Largest lobe of the right lung", "Lies caudally against the diaphragm"],
                    connections: "Part of right lung; right caudal lobar bronchus; sits on diaphragm",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Caudal Lobe of Left Lung",
                    aliases: ["Left caudal lobe", "Left diaphragmatic lobe"],
                    function: "The caudal (most posterior) lobe of the left lung; lies against the diaphragm; one of only two lobes of the left lung",
                    commonConfusions: ["Left lung has only 2 lobes: cranial and caudal — no middle, no accessory", "Right caudal lobe is larger than left caudal lobe"],
                    examTips: ["Left lung = cranial lobe + caudal lobe only", "Caudal lobe = most posterior, rests on diaphragm", "If you can see only 2 lobes on one side, you are looking at the LEFT lung"],
                    connections: "Part of left lung; left caudal lobar bronchus; rests on diaphragm",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Right Bronchus",
                    aliases: ["Right primary bronchus", "Right main bronchus", "Principal bronchus (right)"],
                    function: "The right main-stem bronchus; branches off the trachea at the carina and enters the root of the right lung, supplying air to all four right lung lobes",
                    commonConfusions: ["The right bronchus is wider and more vertical than the left — foreign bodies tend to lodge on the right", "Do not confuse with the left bronchus; look for which side of the tracheal bifurcation each branch goes to"],
                    examTips: ["Gross ID: follow the trachea to its Y-shaped bifurcation (carina); right branch → right bronchus", "Right bronchus = shorter, wider, more vertical than left", "Part of the Root of Lung structures at the hilum"],
                    connections: "Trachea → right bronchus → right lung lobar bronchi (cranial, middle, caudal, accessory)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Left Bronchus",
                    aliases: ["Left primary bronchus", "Left main bronchus", "Principal bronchus (left)"],
                    function: "The left main-stem bronchus; branches off the trachea at the carina and enters the root of the left lung, supplying air to the two left lung lobes",
                    commonConfusions: ["Left bronchus is narrower and more oblique than the right", "Both bronchi arise at the carina — identify left vs right by which lung they enter"],
                    examTips: ["Gross ID: follow trachea to bifurcation; left branch → left bronchus → left lung", "Left bronchus = longer, narrower, more angled than right", "Part of the Root of Lung structures"],
                    connections: "Trachea → left bronchus → left lung lobar bronchi (cranial, caudal)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Root of Lung",
                    aliases: ["Pulmonary hilum", "Lung root"],
                    function: "Entry/exit point of lung where the main bronchus, pulmonary artery, pulmonary veins, lymphatics, and nerves enter and exit the lung",
                    commonConfusions: ["Root of lung = the stalk of structures at the hilum; not the base of the lung"],
                    examTips: ["Practical ID: cluster of structures (bronchus + vessels) at the medial surface of the lung where they enter", "The pulmonary ligament extends below the root"],
                    histology: "Contains bronchial wall (cartilage, smooth muscle, respiratory epithelium), pulmonary artery (elastic wall), pulmonary veins",
                    connections: "Main bronchus → lung; pulmonary artery (from right ventricle/trunk) → lung; pulmonary veins (from lung) → left atrium",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Vocal Folds",
                    aliases: ["True vocal cords", "Vocal cords", "Vocal ligaments"],
                    function: "Vibrate as air passes between them to produce sound; also help close the airway (glottic closure) during swallowing to protect the lower airways",
                    commonConfusions: ["Vocal folds (true cords) vs vestibular folds (false cords) — only the true vocal folds produce sound", "The glottis is the opening BETWEEN the vocal folds; the folds themselves are the tissue structures flanking it"],
                    examTips: ["Practical ID: look inside larynx near the glottic opening — paired whitish ridges flanking the glottic slit", "The gap between the vocal folds = glottis; folds themselves are on either side", "Vibration of vocal folds = phonation (sound production)"],
                    histology: "Stratified squamous epithelium covering the true vocal folds (resistant to vibration/mechanical stress); underlying lamina propria contains the vocal ligament (elastic tissue) and vocalis muscle",
                    connections: "Located inside the larynx, flanking the glottis; attached to thyroid cartilage anteriorly and arytenoid cartilages posteriorly",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Pleura",
                    aliases: ["Pleural membrane", "Serous membrane (thoracic)"],
                    function: "Serous membrane associated with the lungs and thoracic cavity; thoracic equivalent of the peritoneum in the abdomen; reduces friction during breathing, allows smooth lung expansion/contraction, and compartmentalizes the pleural cavities",
                    commonConfusions: ["Pleura (thorax/lungs) vs peritoneum (abdomen) vs pericardium (heart) — all three are serous membranes lined by simple squamous mesothelium; location distinguishes them", "Pleural cavity vs peritoneal cavity: pleural = around lungs in thorax; peritoneal = around digestive organs in abdomen"],
                    examTips: ["MASTER CONCEPT: pleura = peritoneum = pericardium = all simple squamous mesothelium — this is the unifying concept of serous membranes", "Parietal pleura lines the thoracic wall; visceral pleura covers the lungs — same mesothelium, different location", "Pleural fluid between the layers reduces friction during breathing"],
                    histology: "Simple squamous mesothelium (mesothelial cells); thin underlying connective tissue; pleural fluid fills the potential pleural cavity space",
                    connections: "Parietal pleura lines thoracic wall; visceral pleura adheres to lung surface; pleural cavity (potential space) between the two layers contains serous fluid",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Parietal Pleura",
                    aliases: ["Pleura parietalis", "Thoracic wall lining"],
                    function: "The layer of pleura lining the inner thoracic body wall (and diaphragm); forms the outer boundary of the pleural cavity; moves with the chest wall during breathing",
                    commonConfusions: ["Parietal (wall) vs visceral (lung surface) — parietal pleura is attached to the thoracic wall, not to the lung", "Parietal pleura also covers the diaphragm (diaphragmatic pleura) and mediastinum (mediastinal pleura)"],
                    examTips: ["Practical ID: thin shiny membrane lining the inside of the thoracic wall — peels away from the wall when lungs/pleura are reflected", "Parietal pleura → visceral pleura transition occurs at the lung hilum (root of lung)"],
                    histology: "Simple squamous mesothelium with underlying connective tissue; continuous with visceral pleura at the hilum",
                    connections: "Lines thoracic body wall, diaphragm (superior surface), and mediastinum; continuous with visceral pleura at lung root/hilum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respiratoryCat.id,
                    name: "Visceral Pleura",
                    aliases: ["Pleura visceralis", "Pulmonary pleura"],
                    function: "The layer of pleura directly adhering to and covering the lung surface; provides a smooth serous interface between the lung and thoracic wall during respiratory movements",
                    commonConfusions: ["Visceral pleura vs visceral peritoneum: same concept — both are the organ-covering layer of their respective serous membrane systems, both are simple squamous mesothelium", "The visceral pleura cannot be easily separated from the lung surface (it is adherent)"],
                    examTips: ["Practical ID: thin glistening membrane tightly coating the outer lung surface — visible as a thin layer between lung lobes in fissures", "COMPARISON: visceral pleura (lungs) = visceral peritoneum (abdominal organs) = visceral pericardium (heart) — all simple squamous mesothelium"],
                    histology: "Simple squamous mesothelium adhering to the outer surface of the lung; continuous with the parietal pleura at the hilum",
                    connections: "Adheres tightly to lung surface; continuous with parietal pleura at lung root; visceral pleura dips into interlobar fissures",
                    highYield: true
                ),
            ])
        }

        // MARK: Circulatory System (expanded)
        if let circulatoryCat = categories.first(where: { $0.name == "Circulatory System" }) {
            structures.append(contentsOf: [

                // MARK: Heart Chambers
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Heart",
                    aliases: ["Cardiac pump", "Cor"],
                    function: "Central muscular pump driving blood through pulmonary and systemic circuits; enclosed by pericardial sac",
                    commonConfusions: ["Heart muscle (myocardium) is NOT nourished by blood in heart chambers — it needs its own coronary circulation"],
                    examTips: ["Practical ID: centrally located in thoracic cavity inside pericardial sac", "Chambers lined internally by endocardium, continuous with vessel endothelium", "Mostly cardiac muscle tissue"],
                    histology: "Cardiac muscle (striated, branched, intercalated discs, central single nucleus); chambers lined by endocardium (simple squamous endothelium)",
                    connections: "Cranial/caudal vena cava → right heart → pulmonary trunk → lungs → pulmonary veins → left heart → aorta → systemic circulation",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Right Atrium",
                    aliases: ["Right atrial chamber"],
                    function: "Thin-walled receiving chamber for deoxygenated blood returning from the body via cranial/caudal vena cava and coronary sinus",
                    commonConfusions: ["In the fetus, some caudal vena cava blood passes from right atrium through foramen ovale directly into left atrium, bypassing the lungs"],
                    examTips: ["Receives: cranial vena cava, caudal vena cava, coronary sinus", "Adult flow: cranial/caudal vena cava → right atrium → tricuspid valve → right ventricle", "Fetal: some blood crosses foramen ovale to left atrium"],
                    histology: "Thin myocardium; lined by endocardium (simple squamous)",
                    connections: "Cranial/caudal vena cava → right atrium → tricuspid valve → right ventricle",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Left Atrium",
                    aliases: ["Left atrial chamber"],
                    function: "Thin-walled receiving chamber for oxygenated blood from pulmonary veins",
                    commonConfusions: [],
                    examTips: ["Adult flow: pulmonary veins → left atrium → bicuspid valve → left ventricle", "Fetal: also receives blood from right atrium through foramen ovale"],
                    histology: "Thin myocardium; lined by endocardium (simple squamous)",
                    connections: "Pulmonary veins → left atrium → bicuspid valve → left ventricle",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Right Ventricle",
                    aliases: ["Right ventricular chamber"],
                    function: "Pumps deoxygenated blood into the pulmonary trunk toward the lungs",
                    commonConfusions: ["In the fetus, because fetal lungs are nonfunctional, most right ventricular output bypasses the lungs via the ductus arteriosus into the aorta"],
                    examTips: ["Flow: right atrium → tricuspid valve → right ventricle → pulmonary valve → pulmonary trunk", "Thinner wall than left ventricle — lower pressure circuit"],
                    histology: "Thinner myocardium than left ventricle; lined by endocardium",
                    connections: "Right atrium → (tricuspid valve) → right ventricle → (pulmonary valve) → pulmonary trunk",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Left Ventricle",
                    aliases: ["Left ventricular chamber"],
                    function: "Pumps oxygenated blood into systemic circulation via the aorta",
                    commonConfusions: [],
                    examTips: ["Flow: left atrium → bicuspid valve → left ventricle → aortic valve → ascending aorta", "Thicker wall than right ventricle — must pump against higher systemic pressure"],
                    histology: "Thick myocardium; lined by endocardium",
                    connections: "Left atrium → (bicuspid valve) → left ventricle → (aortic valve) → ascending aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Auricles",
                    aliases: ["Atrial appendages", "Left and right auricles"],
                    function: "Flap-like extensions of atria that increase atrial filling and reservoir capacity",
                    commonConfusions: ["Auricle ≠ atrium — auricle is the external flap/appendage; atrium is the chamber itself"],
                    examTips: ["Practical ID: flap-like external projections over atrial region", "Useful for orienting the heart externally before opening it"],
                    histology: "Thin cardiac muscle with endocardial lining",
                    connections: "Extension of right and left atria",
                    highYield: false
                ),

                // MARK: Heart Valves
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Tricuspid Valve",
                    aliases: ["Right atrioventricular valve", "Right AV valve"],
                    function: "Prevents backflow from right ventricle into right atrium during ventricular contraction",
                    commonConfusions: [],
                    examTips: ["Between right atrium and right ventricle", "Flow: right atrium → tricuspid valve → right ventricle", "Mnemonic: 'Try before you buy!' (Tri before Bi) — blood passes through the TRIcuspid valve BEFORE the BIcuspid valve in the heart"],
                    histology: "Fibrous connective tissue cusps; attached to papillary muscles via chordae tendineae",
                    connections: "Right atrium → tricuspid valve → right ventricle",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Bicuspid Valve",
                    aliases: ["Mitral valve", "Left atrioventricular valve", "Left AV valve"],
                    function: "Prevents backflow from left ventricle into left atrium during ventricular contraction",
                    commonConfusions: [],
                    examTips: ["Between left atrium and left ventricle", "Flow: left atrium → bicuspid valve → left ventricle", "Also called mitral valve", "Mnemonic: 'Try before you buy!' (Tri before Bi) — blood passes TRIcuspid FIRST, then BIcuspid (Mitral) second"],
                    histology: "Fibrous connective tissue cusps; attached to papillary muscles via chordae tendineae",
                    connections: "Left atrium → bicuspid valve → left ventricle",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Pulmonary Valve",
                    aliases: ["Pulmonary semilunar valve"],
                    function: "Prevents backflow from pulmonary trunk into right ventricle after ventricular contraction",
                    commonConfusions: [],
                    examTips: ["Between right ventricle and pulmonary trunk", "Semilunar (half-moon shaped) cusps"],
                    histology: "Fibrous connective tissue semilunar cusps; no chordae tendineae",
                    connections: "Right ventricle → pulmonary valve → pulmonary trunk",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Aortic Valve",
                    aliases: ["Aortic semilunar valve"],
                    function: "Prevents backflow from aorta into left ventricle after ventricular contraction",
                    commonConfusions: [],
                    examTips: ["Between left ventricle and ascending aorta", "Semilunar cusps — same design as pulmonary valve"],
                    histology: "Fibrous connective tissue semilunar cusps; no chordae tendineae",
                    connections: "Left ventricle → aortic valve → ascending aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Chordae Tendineae",
                    aliases: ["Heart strings", "Tendinous cords"],
                    function: "Prevent AV valve cusps from flipping backward into atria during ventricular contraction",
                    commonConfusions: [],
                    examTips: ["Associated with: tricuspid valve (right) and bicuspid/mitral valve (left)", "Practical ID: string-like cords inside ventricular chambers attached to valve cusps and papillary muscles"],
                    histology: "Dense fibrous connective tissue (collagen)",
                    connections: "Papillary muscles → chordae tendineae → AV valve cusps",
                    highYield: false
                ),

                // MARK: Coronary Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Left Coronary Artery",
                    aliases: ["Coronary artery", "Cardiac artery"],
                    function: "Supplies oxygenated blood to myocardium — heart muscle cannot be nourished by blood inside the chambers",
                    commonConfusions: [],
                    examTips: ["Branches from ascending aorta just above aortic valve", "Practical ID: vessel visible on ventral heart surface"],
                    histology: "Artery: thick tunica media with smooth muscle; lined by simple squamous endothelium",
                    connections: "Ascending aorta → coronary arteries → myocardial capillaries → cardiac veins → coronary sinus → right atrium",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Great Cardiac Vein",
                    aliases: ["Cardiac vein"],
                    function: "Drains myocardium and delivers venous blood toward the coronary sinus",
                    commonConfusions: [],
                    examTips: ["Practical ID: vein running alongside coronary artery on heart surface"],
                    histology: "Vein: thinner wall, larger lumen; lined by simple squamous endothelium",
                    connections: "Myocardial capillaries → cardiac veins → coronary sinus → right atrium",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Coronary Sinus",
                    aliases: ["Cardiac sinus"],
                    function: "Collects venous blood from cardiac veins and drains it into the right atrium",
                    commonConfusions: [],
                    examTips: ["Practical ID: sac-like venous structure on dorsal heart surface — may need to lift heart to see it"],
                    histology: "Venous structure; endothelial lining",
                    connections: "Cardiac veins → coronary sinus → right atrium",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Left Azygos Vein",
                    aliases: ["Azygos vein"],
                    function: "Drains intercostal and thoracic wall blood; associated with coronary sinus drainage in fetal pig",
                    commonConfusions: [],
                    examTips: ["Practical ID: vein lateral to pulmonary arteries, draining thoracic wall"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Thoracic wall/intercostal spaces → azygos vein → coronary sinus or caudal vena cava",
                    highYield: false
                ),

                // MARK: Aorta and Major Branches
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Ascending Aorta",
                    aliases: ["Proximal aorta"],
                    function: "First segment of aorta leaving the left ventricle; gives rise to coronary arteries",
                    commonConfusions: [],
                    examTips: ["Closest aortic segment to the heart", "Flow: left ventricle → aortic valve → ascending aorta"],
                    histology: "Elastic artery: thick wall with abundant elastic fibers in tunica media; simple squamous endothelium",
                    connections: "Left ventricle → ascending aorta → arch of aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Arch of the Aorta",
                    aliases: ["Aortic arch"],
                    function: "Curved aortic segment giving rise to major branches supplying cranial/forelimb regions; curves to the left in fetal pig",
                    commonConfusions: [],
                    examTips: ["Practical ID: curved portion of aorta after ascending segment", "Gives rise to brachiocephalic trunk and other cranial branches"],
                    histology: "Elastic artery; thick wall with elastic fibers",
                    connections: "Ascending aorta → aortic arch → brachiocephalic trunk → descending aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Descending Aorta",
                    aliases: ["Thoracic aorta", "Abdominal aorta"],
                    function: "Continuation of aorta running caudally; supplies thoracic, abdominal, pelvic, and hindlimb regions",
                    commonConfusions: ["At cross-section ID stations: the aorta is always just to the LEFT of the spine — use this to orient yourself and distinguish it from the vena cava (which is to the right)"],
                    examTips: ["Flow: ascending aorta → arch → descending aorta → systemic branches (celiac, mesenteric, renal, iliac)", "ORIENTATION TIP: aorta = just LEFT of spine in cross-section; vena cava = just RIGHT of spine — use this to identify both vessels and orient the specimen"],
                    histology: "Elastic/muscular artery depending on segment; simple squamous endothelium",
                    connections: "Arch of aorta → descending aorta → celiac trunk, cranial mesenteric artery, renal arteries, iliac arteries",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Brachiocephalic Trunk",
                    aliases: ["Brachiocephalic artery", "Innominate artery"],
                    function: "Large arterial trunk from aortic arch routing oxygenated blood toward head, neck, and forelimb circulation",
                    commonConfusions: ["Do NOT confuse with brachiocephalic VEINS, which are venous return pathways — same region but opposite direction"],
                    examTips: ["Practical ID: major arterial trunk branching from aortic arch", "'Trunk' means it gives rise to smaller arteries"],
                    histology: "Artery: thick tunica media with smooth muscle and elastic fibers",
                    connections: "Aortic arch → brachiocephalic trunk → common carotid arteries + subclavian arteries",
                    highYield: true
                ),

                // MARK: Head and Neck Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Common Carotid Arteries",
                    aliases: ["Left/right common carotid", "Carotid arteries"],
                    function: "Paired arteries supplying oxygenated blood to head and brain regions",
                    commonConfusions: ["Arteries (carotids) are red-injected, thicker-walled; jugular veins are larger, more superficial, and blue-injected — important practical distinction"],
                    examTips: ["Practical ID: ascending arterial pair in neck region", "Arteries usually round in cross-section; veins more irregular/collapsed"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Brachiocephalic trunk → common carotid arteries → head/brain",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "External Jugular Veins",
                    aliases: ["Jugular veins", "External jugulars"],
                    function: "Large superficial veins along the lateroventral neck draining head/neck blood toward brachiocephalic veins",
                    commonConfusions: [],
                    examTips: ["Practical ID: large superficial veins along lateroventral neck — the most prominent veins in the neck region", "Flow: external jugular veins → brachiocephalic veins → cranial vena cava"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Head/neck → external jugular veins → brachiocephalic veins → cranial vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Internal Jugular Veins",
                    aliases: ["Internal jugulars"],
                    function: "Deeper jugular veins draining deeper head/neck regions",
                    commonConfusions: ["External jugular = more superficial/lateroventral; internal jugular = deeper"],
                    examTips: ["Flow: internal jugular veins → brachiocephalic veins → cranial vena cava"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Deep head/neck structures → internal jugular veins → brachiocephalic veins → cranial vena cava",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Brachiocephalic Veins",
                    aliases: ["Left/right brachiocephalic veins", "Innominate veins"],
                    function: "Large paired veins formed by jugular and subclavian venous convergence, draining head, neck, and forelimbs into cranial vena cava",
                    commonConfusions: ["Brachiocephalic VEINS = venous return; brachiocephalic TRUNK = arterial — same naming region, opposite flow direction"],
                    examTips: ["Flow: external/internal jugular + subclavian veins → brachiocephalic veins → cranial vena cava"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Jugular veins + subclavian veins → brachiocephalic veins → cranial vena cava",
                    highYield: true
                ),

                // MARK: Pulmonary Circuit
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Pulmonary Trunk",
                    aliases: ["Pulmonary artery trunk", "Main pulmonary artery"],
                    function: "Carries deoxygenated blood from right ventricle toward the lungs; a 'trunk' because it gives rise to left and right pulmonary arteries",
                    commonConfusions: ["Pulmonary trunk/arteries carry deoxygenated blood — exception to the rule that arteries carry oxygenated blood"],
                    examTips: ["Emerges from right ventricle", "Flow: right ventricle → pulmonary valve → pulmonary trunk → right/left pulmonary arteries", "In fetal pig, ductus arteriosus connects pulmonary trunk to aorta"],
                    histology: "Elastic artery: thick wall with elastic fibers; simple squamous endothelium",
                    connections: "Right ventricle → pulmonary trunk → (ductus arteriosus fetal) + right/left pulmonary arteries",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Pulmonary Arteries",
                    aliases: ["Right/left pulmonary arteries"],
                    function: "Carry deoxygenated blood to pulmonary capillaries in right and left lungs",
                    commonConfusions: ["IMPORTANT EXCEPTION: pulmonary arteries are arteries but carry low-oxygen blood — named by direction (away from heart), not oxygen content"],
                    examTips: ["Branch from pulmonary trunk", "Pulmonary trunk bifurcates into right and left pulmonary arteries at dorsal heart region; pulmonary veins lie nearby entering left atrium"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Pulmonary trunk → right/left pulmonary arteries → pulmonary capillaries",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Pulmonary Veins",
                    aliases: ["Right/left pulmonary veins"],
                    function: "Return oxygenated blood from lungs to the left atrium; usually four veins total",
                    commonConfusions: ["IMPORTANT EXCEPTION: pulmonary veins are veins but carry oxygen-rich blood — named by direction (toward heart), not oxygen content"],
                    examTips: ["Flow: pulmonary capillaries → pulmonary veins → left atrium", "Usually four veins total (two per lung)"],
                    histology: "Vein: thinner wall than pulmonary arteries; simple squamous endothelium",
                    connections: "Lung capillaries → pulmonary veins → left atrium",
                    highYield: true
                ),

                // MARK: Venae Cavae
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Cranial Vena Cava",
                    aliases: ["Superior vena cava", "Anterior vena cava"],
                    function: "Returns deoxygenated blood from head, neck, and forelimbs to the right atrium (enters cranially)",
                    commonConfusions: [],
                    examTips: ["Enters right atrium cranially", "Flow: brachiocephalic veins → cranial vena cava → right atrium"],
                    histology: "Large vein: thin wall, very large lumen; simple squamous endothelium",
                    connections: "Brachiocephalic veins → cranial vena cava → right atrium",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Caudal Vena Cava",
                    aliases: ["Inferior vena cava", "Posterior vena cava"],
                    function: "Returns deoxygenated blood from caudal body regions and visceral organs to the right atrium (enters caudally); in fetus also receives blood from ductus venosus",
                    commonConfusions: [],
                    examTips: ["Enters right atrium caudally", "Fetal: ductus venosus carries umbilical vein blood into caudal vena cava — review notes emphasize close relationship with foramen ovale"],
                    histology: "Large vein: thin wall, very large lumen; simple squamous endothelium",
                    connections: "Caudal body/viscera + ductus venosus (fetal) → caudal vena cava → right atrium",
                    highYield: true
                ),

                // MARK: Thoracic Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Subclavian Arteries and Veins",
                    aliases: ["Subclavian artery", "Subclavian vein"],
                    function: "Paired vessels near thoracic inlet; subclavian arteries supply forelimbs, subclavian veins drain forelimbs into brachiocephalic veins",
                    commonConfusions: [],
                    examTips: ["Subclavian veins → brachiocephalic veins → cranial vena cava", "Located near thoracic inlet/forelimb root"],
                    histology: "Arteries: thick tunica media; veins: thin wall; both with simple squamous endothelium",
                    connections: "Brachiocephalic trunk → subclavian arteries → forelimb; forelimb → subclavian veins → brachiocephalic veins",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Axillary Arteries and Veins",
                    aliases: ["Axillary artery", "Axillary vein"],
                    function: "Major forelimb vessels continuing from subclavian region; supply and drain forelimb/shoulder",
                    commonConfusions: [],
                    examTips: ["Practical ID: located toward shoulder/forelimb root"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Subclavian → axillary → forelimb vessels",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Thyrocervical Trunk",
                    aliases: ["Thoracocervical artery"],
                    function: "Arterial branch supplying cervical and thoracic-associated tissues (thyroid/cervical or thoracic/cervical supply territory)",
                    commonConfusions: [],
                    examTips: ["Name describes region: thyro = thyroid, cervical = neck/cervical area"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Subclavian artery or aortic arch → thyrocervical trunk → cervical/thoracic tissues",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Internal Thoracic Arteries and Veins",
                    aliases: ["Internal mammary arteries/veins"],
                    function: "Paired vessels along the internal thoracic wall; supply and drain thoracic wall",
                    commonConfusions: [],
                    examTips: ["Practical ID: vessels along internal thoracic wall"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Subclavian artery → internal thoracic artery → thoracic wall; thoracic wall → internal thoracic vein → brachiocephalic vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "External Thoracic Arteries",
                    aliases: ["External thoracic artery"],
                    function: "Arterial branches supplying superficial thoracic/pectoral regions",
                    commonConfusions: [],
                    examTips: ["Supply thoracic wall and pectoral muscle region"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Axillary artery → external thoracic arteries → pectoral/thoracic wall",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Subscapular Veins",
                    aliases: ["Left/right subscapular veins"],
                    function: "Drain scapular/shoulder tissues into larger venous return pathways",
                    commonConfusions: [],
                    examTips: ["Associated with shoulder/scapular region"],
                    histology: "Vein: thin wall; simple squamous endothelium",
                    connections: "Shoulder/scapular tissues → subscapular veins → axillary veins",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Costocervical Veins",
                    aliases: ["Left/right costocervical veins"],
                    function: "Return blood from neck and thoracic wall regions into larger venous pathways",
                    commonConfusions: [],
                    examTips: ["Associated with cervical and thoracic wall drainage"],
                    histology: "Vein: thin wall; simple squamous endothelium",
                    connections: "Neck/thoracic wall → costocervical veins → subclavian or brachiocephalic veins",
                    highYield: false
                ),

                // MARK: Portal and Abdominal Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Celiac Artery",
                    aliases: ["Coeliac artery", "Celiac trunk", "Celiac axis"],
                    function: "Major arterial trunk from descending aorta supplying foregut organs (stomach, liver, spleen, pancreas); a 'trunk' because it gives off branches",
                    commonConfusions: [],
                    examTips: ["Practical ID: first major abdominal branch from descending aorta", "Branches into hepatic artery, splenic/lienic artery, and gastric artery"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Descending aorta → celiac trunk → hepatic artery + splenic artery + gastric artery",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Hepatic Artery",
                    aliases: ["Hepatic arterial supply"],
                    function: "Brings oxygenated systemic blood to liver tissue",
                    commonConfusions: ["Hepatic artery ≠ hepatic portal vein — hepatic artery brings oxygenated blood; portal vein brings nutrient-rich venous blood from GI organs"],
                    examTips: ["Practical ID: artery entering liver alongside portal vein"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Celiac trunk → hepatic artery → liver",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Hepatic Portal Vein",
                    aliases: ["Portal vein", "Portal circulation"],
                    function: "Carries nutrient-rich blood from stomach/intestines to liver sinusoids before systemic return — unique venous connection",
                    commonConfusions: ["Portal vein connects two capillary beds (GI and liver) — this is called a portal system"],
                    examTips: ["Flow: digestive organs → mesenteric/gastric/splenic veins → hepatic portal vein → liver sinusoids → hepatic veins → caudal vena cava", "High yield portal circulation concept"],
                    histology: "Vein: relatively thicker wall than typical veins due to portal pressure; simple squamous endothelium",
                    connections: "GI capillaries → mesenteric/gastric/splenic veins → hepatic portal vein → liver sinusoids",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Liver Sinusoids",
                    aliases: ["Hepatic sinusoids"],
                    function: "Highly permeable capillary-like vascular spaces in liver allowing exchange between blood and hepatocytes for processing",
                    commonConfusions: [],
                    examTips: ["Sinusoids are discontinuous/highly permeable capillaries — suitable for liver metabolism", "Receive both portal vein blood and hepatic artery blood"],
                    histology: "Discontinuous sinusoidal endothelium (highly permeable); Kupffer cells (liver macrophages) present",
                    connections: "Hepatic portal vein + hepatic artery → liver sinusoids → hepatic veins",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Hepatic Vein",
                    aliases: ["Hepatic veins"],
                    function: "Carries processed blood away from liver into caudal vena cava",
                    commonConfusions: [],
                    examTips: ["Flow: liver sinusoids → hepatic vein → caudal vena cava"],
                    histology: "Vein: thin wall; simple squamous endothelium",
                    connections: "Liver sinusoids → hepatic vein → caudal vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Cranial Mesenteric Artery",
                    aliases: ["Superior mesenteric artery"],
                    function: "Major artery supplying much of the intestine with oxygenated blood; travels in/near mesentery with intestinal loops",
                    commonConfusions: [],
                    examTips: ["Practical ID: large artery visible in mesentery among intestinal loops"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Descending aorta → cranial mesenteric artery → jejunal arteries → intestinal capillaries",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Caudal Mesenteric Artery",
                    aliases: ["Inferior mesenteric artery"],
                    function: "Supplies distal large intestine and caudal GI region with oxygenated blood",
                    commonConfusions: [],
                    examTips: ["Supplies distal colon and rectal regions"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Descending aorta → caudal mesenteric artery → distal large intestine",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Mesenteric Vein",
                    aliases: ["Mesenteric veins"],
                    function: "Drains intestines and carries nutrient-rich venous blood toward the hepatic portal vein",
                    commonConfusions: [],
                    examTips: ["Flow: intestinal capillaries → mesenteric vein → hepatic portal vein → liver"],
                    histology: "Vein: thin wall; simple squamous endothelium",
                    connections: "Intestinal capillaries → mesenteric vein → hepatic portal vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Jejunal Arteries and Veins",
                    aliases: ["Jejunal vessels"],
                    function: "Supply and drain jejunum; jejunal arteries bring oxygenated blood, jejunal veins drain absorbed nutrients into portal circulation",
                    commonConfusions: [],
                    examTips: ["Practical ID: vessels visible in mesentery associated with jejunum loops"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Cranial mesenteric artery → jejunal arteries → jejunum; jejunum → jejunal veins → mesenteric vein → portal vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Gastric Artery and Vein",
                    aliases: ["Gastric vessels"],
                    function: "Supply and drain stomach; gastric artery delivers oxygenated blood, gastric vein drains toward portal circulation",
                    commonConfusions: [],
                    examTips: ["Associated with stomach curvature/wall"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Celiac trunk → gastric artery → stomach; stomach → gastric vein → portal vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Gastroepiploic Artery and Vein",
                    aliases: ["Gastroepiploic vessels"],
                    function: "Supply and drain stomach curvature and omentum-associated tissues",
                    commonConfusions: [],
                    examTips: ["Associated with stomach curvature/greater omentum region"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Celiac/gastric branches → gastroepiploic artery → stomach/omentum; → gastroepiploic vein → portal circulation",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Splenic Artery and Vein",
                    aliases: ["Lienic artery and vein", "Splenic/lienic vessels"],
                    function: "Supply and drain spleen; splenic vein drains into portal circulation",
                    commonConfusions: [],
                    examTips: ["Splenic = lienic — the same vessels (lienic is the older term)", "Splenic vein contributes to hepatic portal vein"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Celiac trunk → splenic artery → spleen; spleen → splenic vein → portal vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Splenogastric Vein",
                    aliases: ["Lienogastric vein"],
                    function: "Drains venous blood from spleen and stomach-associated region toward larger portal venous routes",
                    commonConfusions: [],
                    examTips: ["Splenogastric = lienogastric — same vessel, different naming convention"],
                    histology: "Vein: thin wall; simple squamous endothelium",
                    connections: "Spleen/stomach region → splenogastric vein → hepatic portal vein",
                    highYield: false
                ),

                // MARK: Renal Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Renal Arteries",
                    aliases: ["Renal artery", "Kidney arteries"],
                    function: "Supply blood to kidneys for filtration; branch directly from abdominal aorta",
                    commonConfusions: [],
                    examTips: ["Flow: aorta → renal artery → kidney → renal vein → caudal vena cava", "Practical ID: vessels entering kidney hilum"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Descending aorta → renal arteries → kidney",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Renal Veins",
                    aliases: ["Renal vein", "Kidney veins"],
                    function: "Return filtered blood from kidneys to caudal vena cava",
                    commonConfusions: [],
                    examTips: ["Flow: kidney → renal vein → caudal vena cava"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Kidney → renal veins → caudal vena cava",
                    highYield: true
                ),

                // MARK: Pelvic and Hindlimb Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Common Iliac Vein",
                    aliases: ["Common iliac"],
                    function: "Large pelvic vein collecting venous return from internal and external iliac veins; contributes to caudal vena cava",
                    commonConfusions: ["IMPORTANT PIG-SPECIFIC: pigs have a COMMON ILIAC VEIN but NO common iliac artery — the arterial side divides directly into internal and external iliac arteries"],
                    examTips: ["Pig-specific: common iliac vein exists; common iliac artery does NOT — important exam distinction"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Internal iliac vein + external iliac vein → common iliac vein → caudal vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Internal Iliac Artery and Vein",
                    aliases: ["Hypogastric artery/vein"],
                    function: "Supply and drain pelvic, reproductive, and umbilical-associated regions; internal iliac artery is CRITICAL in maternal-to-fetal circulation trace — often forgotten",
                    commonConfusions: [],
                    examTips: ["VERY IMPORTANT: often forgotten in maternal-to-fetal circulatory trace", "Maternal path: descending aorta → internal iliac artery → uterine artery → placenta", "Drains pelvic and reproductive organs"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Descending aorta → internal iliac artery → pelvic/reproductive organs/umbilical vessels; pelvic organs → internal iliac vein → common iliac vein",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "External Iliac Artery and Vein",
                    aliases: ["External iliac"],
                    function: "Major vessels continuing toward hindlimb; supply and drain hindlimb",
                    commonConfusions: [],
                    examTips: ["Continuation becomes femoral artery/vein in the hindlimb"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Descending aorta → external iliac artery → femoral artery; femoral vein → external iliac vein → common iliac vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Femoral Vessels",
                    aliases: ["Femoral artery", "Femoral vein"],
                    function: "Major vessels of the hindlimb; supply and drain hindlimb musculature",
                    commonConfusions: [],
                    examTips: ["Practical ID: pass through hindlimb region", "Continuation of external iliac vessels"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "External iliac → femoral artery → hindlimb; hindlimb → femoral vein → external iliac vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Deep Femoral Artery and Vein",
                    aliases: ["Deep femoral vessels", "Profunda femoris"],
                    function: "Branch vessels serving deeper thigh and hindlimb structures",
                    commonConfusions: [],
                    examTips: ["Branches off femoral vessels toward deeper thigh musculature"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Femoral artery → deep femoral artery → deep thigh muscles; → deep femoral vein → femoral vein",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Deep Circumflex Iliac Artery and Vein",
                    aliases: ["Deep circumflex iliac vessels"],
                    function: "Supply and drain lateral abdominal wall and iliac-associated tissues",
                    commonConfusions: [],
                    examTips: ["Associated with lateral abdominal wall near iliac region"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "External iliac artery → deep circumflex iliac artery → lateral abdominal wall",
                    highYield: false
                ),

                // MARK: Reproductive Vessels
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Testicular Artery",
                    aliases: ["Gonadal artery (male)", "Internal spermatic artery"],
                    function: "Supplies oxygenated blood supporting spermatogenesis and endocrine activity; runs within spermatic cord",
                    commonConfusions: [],
                    examTips: ["Practical ID: vessel running within spermatic cord", "Rich vascular supply supports metabolically active sperm production", "Contributes to vascular heat exchange maintaining lower testicular temperature"],
                    histology: "Artery with thick tunica media containing smooth muscle; lined by simple squamous endothelium",
                    connections: "Abdominal aorta → testicular artery → testis (via spermatic cord)",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Testicular Vein",
                    aliases: ["Gonadal vein (male)", "Pampiniform plexus drainage"],
                    function: "Drains venous blood from testis; contributes to thermoregulation via vascular heat exchange",
                    commonConfusions: [],
                    examTips: ["Practical ID: vessel running within spermatic cord", "Vascular heat exchange helps maintain lower testicular temperature"],
                    histology: "Vein with thinner wall and larger lumen than artery; lined by simple squamous endothelium",
                    connections: "Testis → testicular vein → caudal vena cava (right) or renal vein (left)",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Ovarian Artery and Vein",
                    aliases: ["Ovarian vessels", "Gonadal artery/vein (female)"],
                    function: "Supply and drain ovaries; ovarian artery delivers oxygenated blood, ovarian vein drains ovary",
                    commonConfusions: [],
                    examTips: ["Practical ID: vessels associated with ovary and uterine horn region"],
                    histology: "Artery and vein pair; simple squamous endothelium",
                    connections: "Descending aorta → ovarian artery → ovary; ovary → ovarian vein → caudal vena cava or renal vein",
                    highYield: false
                ),

                // MARK: Fetal / Umbilical Circulation
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Umbilical Cord",
                    aliases: ["Umbilical stalk"],
                    function: "Fetal connection between pig and placenta; the major route for fetal-maternal exchange of oxygen, nutrients, and wastes",
                    commonConfusions: ["Do not treat umbilical cord as merely an external structure — it is a major fetal circulatory bundle"],
                    examTips: ["Contains: umbilical vein (1), umbilical arteries (2), allantoic stalk/urachus, and connective tissue", "Oxygen and nutrients: placenta → fetus via umbilical vein; fetal wastes: fetus → placenta via umbilical arteries"],
                    histology: "Wharton's jelly (mucous connective tissue) supporting umbilical vessels",
                    connections: "Placenta ↔ umbilical cord ↔ fetal circulation",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Umbilical Arteries",
                    aliases: ["Umbilical arterial pair"],
                    function: "Paired fetal vessels carrying relatively deoxygenated blood and fetal wastes from fetus to placenta",
                    commonConfusions: ["WHY 'artery' if deoxygenated? Arteries are named by direction relative to the heart (away from fetal heart), NOT by oxygen content — same rule as pulmonary arteries"],
                    examTips: ["Usually TWO vessels (paired); thicker-walled than the single umbilical vein", "Flow: fetal systemic circulation → internal iliac arteries → umbilical arteries → placenta"],
                    histology: "Artery: thick tunica media; simple squamous endothelium",
                    connections: "Internal iliac arteries → umbilical arteries → placenta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Umbilical Vein",
                    aliases: ["Fetal umbilical vein"],
                    function: "Single large vessel carrying oxygenated, nutrient-rich blood from placenta to fetus",
                    commonConfusions: [],
                    examTips: ["Usually a single large thin-walled vessel — contrast with the two thicker umbilical arteries", "Flow: placenta → umbilical vein → ductus venosus → caudal vena cava → right atrium — explicitly emphasized in review notes"],
                    histology: "Vein: thin wall, large lumen; simple squamous endothelium",
                    connections: "Placenta → umbilical vein → ductus venosus → caudal vena cava → right atrium",
                    highYield: true
                ),

                // MARK: Fetal Shunts
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Ductus Venosus",
                    aliases: ["Fetal liver bypass"],
                    function: "Temporary fetal vessel connecting umbilical vein directly to caudal vena cava, bypassing most of the liver",
                    commonConfusions: [],
                    examTips: ["Fetal bypass #1: liver bypass", "Flow: umbilical vein → ductus venosus → caudal vena cava", "Closes after birth; becomes ligamentum venosum"],
                    histology: "Fetal vessel with endothelial lining; closes and becomes fibrous cord after birth",
                    connections: "Umbilical vein → ductus venosus → caudal vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Foramen Ovale",
                    aliases: ["Fetal atrial opening", "Interatrial shunt"],
                    function: "Opening in fetal interatrial septum allowing blood to pass directly from right atrium to left atrium, bypassing pulmonary circuit",
                    commonConfusions: [],
                    examTips: ["Fetal bypass #2: right atrium → left atrium, bypassing pulmonary circuit", "Flow: caudal vena cava → right atrium → foramen ovale → left atrium", "Review notes emphasize close relationship between caudal vena cava entrance and foramen ovale", "Closes after birth when pulmonary pressure changes; becomes fossa ovalis"],
                    histology: "Opening in fibromuscular interatrial septum; closes postnatally",
                    connections: "Caudal vena cava → right atrium → foramen ovale → left atrium → left ventricle → aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Ductus Arteriosus",
                    aliases: ["Fetal arterial shunt", "Arterial duct"],
                    function: "Temporary fetal vessel connecting pulmonary trunk to aorta, bypassing fetal lungs",
                    commonConfusions: [],
                    examTips: ["Fetal bypass #3: pulmonary trunk → aorta, bypassing lungs", "Flow: right ventricle → pulmonary trunk → ductus arteriosus → aorta", "Closes after birth when lungs expand; becomes ligamentum arteriosum"],
                    histology: "Muscular fetal vessel; closes and becomes fibrous ligamentum arteriosum postnatally",
                    connections: "Pulmonary trunk → ductus arteriosus → descending aorta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Ligamentum Arteriosum",
                    aliases: ["Adult remnant of ductus arteriosus"],
                    function: "Fibrous adult remnant of the fetal ductus arteriosus; no longer a functional blood shunt",
                    commonConfusions: [],
                    examTips: ["Ductus arteriosus (fetus) → closes after birth → ligamentum arteriosum (adult)", "Practical ID: fibrous cord between pulmonary trunk and aorta in adults"],
                    histology: "Fibrous connective tissue (closed vessel remnant)",
                    connections: "Between pulmonary trunk and aortic arch (remnant of fetal shunt)",
                    highYield: false
                ),

                // MARK: Circulation Flow Paths (High-Yield Conceptual Entries)
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Systemic Adult Circulation",
                    aliases: ["Adult systemic flow path", "Pulmonary and systemic circuit"],
                    function: "Complete adult circulatory loop: cranial/caudal vena cava → right atrium → tricuspid valve → right ventricle → pulmonary valve → pulmonary trunk → pulmonary arteries → lung capillaries → pulmonary veins → left atrium → bicuspid valve → left ventricle → aortic valve → ascending aorta → arch of aorta → descending aorta → systemic distribution",
                    commonConfusions: ["Key rule: ARTERIES carry blood AWAY from heart; VEINS carry blood TOWARD heart — regardless of oxygen content"],
                    examTips: ["Arteries usually have thicker, rounder walls; veins thinner and more irregular/collapsed", "Memorize complete flow path for practical trace questions"],
                    histology: "Arteries: thick tunica media; veins: thin wall; all with simple squamous endothelium",
                    connections: "Full loop: body → vena cava → right heart → pulmonary circuit → left heart → aorta → body",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Portal Circulation",
                    aliases: ["Hepatic portal system", "Portal flow path"],
                    function: "Nutrient-rich venous blood from GI organs routes through liver before returning to systemic circulation: GI organs → mesenteric/gastric/splenic veins → hepatic portal vein → liver sinusoids → hepatic veins → caudal vena cava",
                    commonConfusions: [],
                    examTips: ["Portal system connects two capillary beds (GI capillaries and liver sinusoids)", "Blood is processed by liver (detoxification, nutrient storage) before systemic return"],
                    histology: "Portal vein and tributaries: thin-walled veins; liver sinusoids: highly permeable discontinuous endothelium",
                    connections: "GI capillaries → mesenteric/gastric/splenic veins → portal vein → liver → hepatic veins → caudal vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: circulatoryCat.id,
                    name: "Maternal-to-Fetal Circulatory Trace",
                    aliases: ["Fetal circulation trace", "Placental circulation"],
                    function: "Complete maternal-to-fetal exchange pathway: descending aorta → internal iliac artery (OFTEN FORGOTTEN) → uterine artery → uterine arterioles → maternal placental capillaries → uterine epithelium barrier → chorioallantoic membrane → fetal capillaries → umbilical venules → umbilical vein → ductus venosus → caudal vena cava",
                    commonConfusions: ["Internal iliac artery is often forgotten in this trace — review notes explicitly warn about this", "Maternal and fetal blood do NOT directly mix — exchange occurs across tissue barriers"],
                    examTips: ["VERY HIGH YIELD trace for practical", "Key vessels: internal iliac artery → uterine artery → placenta → umbilical vein → ductus venosus → caudal vena cava", "Three fetal shunts: ductus venosus (liver bypass), foramen ovale (atrial bypass), ductus arteriosus (pulmonary bypass)"],
                    histology: "Exchange across: uterine epithelium and chorioallantoic membrane; simple squamous endothelium in all vessels",
                    connections: "Maternal aorta → internal iliac → uterine artery → placenta → umbilical vein → ductus venosus → caudal vena cava → right atrium",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Urinary System (expanded)
        if let urinaryCat = categories.first(where: { $0.name == "Urinary System" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Renal Cortex",
                    aliases: ["Kidney cortex"],
                    function: "Outer region containing glomeruli",
                    examTips: ["Site of initial filtration"]
                ),
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Renal Pelvis",
                    aliases: ["Funnel structure"],
                    function: "Collects urine from pyramids",
                    examTips: ["Connects to ureter"]
                ),
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Renal Calyx",
                    aliases: ["Calyces"],
                    function: "Collects urine from collecting ducts",
                    examTips: ["Multiple calyces per kidney"]
                ),
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Renal Pyramid",
                    aliases: ["Medullary pyramid"],
                    function: "Medullary structure containing collecting ducts",
                    examTips: ["Striated appearance"]
                ),
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Urethra",
                    aliases: ["Urinary passage"],
                    function: "Conducts urine from bladder to the exterior; in males also conducts semen",
                    commonConfusions: ["In females: carries only urine; in males: carries both urine and semen (shared reproductive/urinary pathway)", "Female urethra is much shorter than male urethra"],
                    examTips: ["Practical ID in female: short tube from bladder opening into floor of urogenital sinus", "Practical ID in male: long tube running through the penis to the tip (urogenital orifice)"],
                    histology: "Transitional epithelium near bladder, transitioning to stratified squamous near the external opening",
                    connections: "Proximal: urinary bladder; in females: distal end opens into urogenital sinus; in males: runs through prostate, perineum, and penis",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: urinaryCat.id,
                    name: "Adrenal Gland",
                    aliases: ["Suprarenal gland", "Adrenal"],
                    function: "Dual-function endocrine gland: the cortex produces steroid hormones (aldosterone for Na+/K+ balance, cortisol for stress response, sex steroids); the medulla produces catecholamines (epinephrine/norepinephrine) for the fight-or-flight response",
                    commonConfusions: ["Adrenal CORTEX (outer layer) = steroid hormones; Adrenal MEDULLA (inner layer) = catecholamines — do not confuse the two layers", "The adrenal gland is endocrine (releases hormones directly into blood), not exocrine (no duct)"],
                    examTips: ["Practical ID: small, compact gland sitting on the cranial pole of each kidney — look where the renal artery arrives at the kidney and the adrenal is nearby/above", "In fetal pigs, adrenal glands are relatively large compared to adult size", "Two functional zones: cortex (outer, steroid-producing) + medulla (inner, catecholamine-producing) — can be distinguished histologically"],
                    histology: "Cortex: three zones — zona glomerulosa (aldosterone), zona fasciculata (cortisol), zona reticularis (sex steroids) — all steroidogenic cells with lipid droplets; Medulla: modified sympathetic neurons (chromaffin cells) storing epinephrine/norepinephrine in dense-core vesicles",
                    connections: "Located on cranial pole of kidney; receives blood from suprarenal arteries (branches of aorta/renal/phrenic arteries); veins drain to renal vein (left) or IVC (right); no duct — direct hormone secretion into bloodstream",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Male Reproductive
        if let maleRepCat = categories.first(where: { $0.name == "Male Reproductive" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Testis",
                    aliases: ["Testicle", "Male gonad"],
                    function: "Produces sperm via spermatogenesis and testosterone via Leydig cells",
                    commonConfusions: ["Seminiferous tubule epithelium is specialized stratified germinal epithelium — NOT simple cuboidal/columnar/squamous"],
                    examTips: ["One of the more commonly tested reproductive structures", "Practical ID: oval reproductive organ with epididymis attached along one side", "VERY important histology slide: seminiferous tubules, spermatogonia, spermatocytes, spermatids, spermatozoa, Leydig cells", "Leydig cells located between seminiferous tubules — secrete testosterone — VERY HIGH YIELD endocrine concept", "External scrotal position maintains lower temperature for spermatogenesis"],
                    images: [
                        ImageCDN.slide("testis_10x_1.jpeg", magnification: 10),
                        ImageCDN.slide("testis_40x_1.jpeg", magnification: 40),
                    ],
                    histology: "Composed mainly of coiled seminiferous tubules lined by specialized stratified germinal epithelium; Leydig cells (testosterone-secreting) located between tubules; Sertoli cells support sperm maturation within tubules",
                    connections: "Seminiferous tubules → epididymis → ductus deferens",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Epididymus",
                    aliases: ["Epididymis"],
                    function: "Sperm maturation and storage",
                    commonConfusions: ["VERY IMPORTANT: stereocilia on epididymis epithelium are NONMOTILE long projections with absorptive role — NOT true cilia which are motile"],
                    examTips: ["One of the more tested reproductive structures", "Practical ID: coiled structure attached to testis surface", "Lined by pseudostratified columnar epithelium with stereocilia — VERY important histology distinction"],
                    histology: "Pseudostratified columnar epithelium with stereocilia — supports secretion, absorption, and sperm maturation environment; coiled organization provides long maturation pathway in compact space",
                    connections: "Seminiferous tubules → epididymis → ductus deferens",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Ductus Deferens",
                    aliases: ["Vas deferens"],
                    function: "Transports sperm from epididymis toward urethra, especially during ejaculation",
                    commonConfusions: [],
                    examTips: ["Practical ID: firm whitish tube within spermatic cord", "WHY thick smooth muscle: sperm transport requires powerful peristaltic contractions — one of the most muscular ducts in the body"],
                    histology: "Lined by pseudostratified columnar epithelium with surrounding thick smooth muscle — thick muscle enables rapid sperm propulsion; folded mucosa allows flexibility while maintaining lumen integrity",
                    connections: "Epididymis → ductus deferens → urethral region",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Spermatic Cord",
                    aliases: ["Testicular cord"],
                    function: "Provides structural support, blood supply, and sperm transport route for testis; contains ductus deferens, vessels, nerves, and connective tissue",
                    commonConfusions: [],
                    examTips: ["Practical ID: cord-like structure extending superiorly from testis", "Contains: ductus deferens, testicular vessels, nerves, connective tissue"],
                    histology: "Mixed tissues: connective tissue, smooth muscle, vessels, duct epithelium — bundled organization allows protected passage through inguinal canal",
                    connections: "Testis → spermatic cord → inguinal canal → abdominal cavity",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Bulbourethral Glands",
                    aliases: ["Cowper's glands"],
                    function: "Produce lubricating mucus-like secretions contributing to semen and urethral lubrication",
                    commonConfusions: [],
                    examTips: ["Among the tested reproductive structures", "Practical ID: small paired glands near posterior urethral region", "Exocrine glands — secretions travel through ducts into urethra"],
                    histology: "Exocrine glands: secretory portions lined by cuboidal/columnar secretory epithelium; ducts lined by cuboidal epithelium",
                    connections: "Glands → ducts → urethra",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Seminal Vesicles",
                    aliases: ["Seminal glands"],
                    function: "Produce seminal fluid components supporting sperm nutrition and semen volume",
                    commonConfusions: [],
                    examTips: ["Among the more commonly tested reproductive structures", "Practical ID: paired glandular sacs near posterior bladder region", "Exocrine glands — folded glandular mucosa increases secretory surface area"],
                    histology: "Exocrine glands with secretory epithelium (simple columnar/cuboidal); duct system channels fluid into reproductive tract",
                    connections: "Glands → ducts → reproductive tract near bladder/ductus deferens junction",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Prostate",
                    aliases: ["Prostatic gland"],
                    function: "Produces secretions contributing to semen and sperm support",
                    commonConfusions: [],
                    examTips: ["Practical ID: glandular tissue surrounding proximal urethral region", "Position around urethra allows direct contribution to semen pathway"],
                    histology: "Exocrine gland with glandular epithelium (cuboidal/columnar secretory cells) and ducts lined by cuboidal epithelium",
                    connections: "Surrounds proximal urethra; ducts open into urethra",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Penis",
                    aliases: ["Male copulatory organ"],
                    function: "Semen delivery and urine transport",
                    commonConfusions: [],
                    examTips: ["Practical ID: external elongated reproductive structure", "Contains erectile vascular tissue supporting reproductive function"],
                    histology: "Contains erectile vascular tissue, connective tissue, urethral epithelium, and smooth muscle; external surfaces: stratified squamous epithelium; internal urethral epithelium varies regionally",
                    connections: "Urethra → penis → preputial orifice",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Urethra",
                    aliases: ["Male urethra", "Urethral tube"],
                    function: "Shared urinary and reproductive transport pathway; carries urine and semen through penis",
                    commonConfusions: [],
                    examTips: ["Practical ID: tube associated with penile/reproductive structures", "Epithelium changes regionally: more transitional proximally, more protective distally"],
                    histology: "Epithelium changes regionally depending on function and exposure; flexible lumen supports fluid transport",
                    connections: "Bladder + reproductive ducts → urethra → penis → preputial opening",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Preputial Orifice",
                    aliases: ["Preputial opening", "Male urogenital opening"],
                    function: "External outlet for urine and reproductive secretions; key sex-identification structure in fetal pig",
                    commonConfusions: ["Male opening is caudal to umbilical cord — NOT near the tail (a near-tail opening indicates female)"],
                    examTips: ["Practical ID: male opening near umbilical region, NOT near tail", "VERY important sex-identification landmark"],
                    histology: "Transition zone between external protective epithelium and internal mucosal epithelium",
                    connections: "Penis → preputial orifice → external environment",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Scrotum",
                    aliases: ["Scrotal sac"],
                    function: "Maintains testes at lower temperature optimal for spermatogenesis",
                    commonConfusions: [],
                    examTips: ["Practical ID: sac-like external structure near hindlimbs/tail", "External location allows cooler temperature than body core — expandable sac organization supports thermoregulation"],
                    histology: "External surface: stratified squamous epithelium (skin); underlying: connective tissue, smooth muscle, vessels",
                    connections: "Contains testes and spermatic cord",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Inguinal Canal",
                    aliases: ["Inguinal passage"],
                    function: "Passageway allowing transit of spermatic cord, vessels, and nerves between abdominal cavity and scrotal region; supports testicular descent",
                    commonConfusions: [],
                    examTips: ["Practical ID: canal region superior to scrotal structures"],
                    histology: "Contains connective tissue, muscular boundaries, and neurovascular structures — tunnel-like organization allows protected transit between abdomen and scrotum",
                    connections: "Abdominal cavity → inguinal canal → spermatic cord → scrotal region",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Cremasteric Pouch",
                    aliases: ["Cremaster pouch"],
                    function: "Supports testicular positioning and thermoregulation; muscular contraction can raise/lower testes to regulate temperature",
                    commonConfusions: [],
                    examTips: ["Practical ID: muscular tissue surrounding testicular structures"],
                    histology: "Associated with skeletal muscle (cremaster muscle) plus connective tissue and vessels",
                    connections: "Surrounds testis and spermatic cord",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maleRepCat.id,
                    name: "Gubernaculum",
                    aliases: ["Gubernacular cord"],
                    function: "Fibrous developmental structure that guides descent of testes during development",
                    commonConfusions: [],
                    examTips: ["Practical ID: cord-like structure associated with testis/scrotal pathway"],
                    histology: "Primarily connective tissue rich in collagen fibers — fibrous organization provides mechanical guidance for testicular positioning",
                    connections: "Associated with testis and scrotal pathway",
                    highYield: false
                ),
            ])
        }
        
        // MARK: Female Reproductive
        if let femaleRepCat = categories.first(where: { $0.name == "Female Reproductive" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Ovary",
                    aliases: ["Female gonad", "Ovaries"],
                    function: "Produces eggs (ova) via oogenesis and secretes estrogen and progesterone to regulate the reproductive cycle and support pregnancy",
                    commonConfusions: ["Distinguished from testis by location in abdomen near oviduct opening; ovary lacks epididymis", "In fetal pig the ovaries are small and may look like fat deposits — look for the oviduct/fimbriae nearby"],
                    examTips: ["Paired organs located on either side of the dorsal mesentery in the abdominal cavity", "Practical ID: small, oval, slightly granular-textured organs near the distal ends of the uterine horns", "In fetal pigs, appear whitish-pink and smooth; in adults they may have visible follicles or corpora lutea on surface"],
                    histology: "Simple cuboidal to simple squamous (germinal epithelium) overlying a dense connective tissue cortex containing follicles in various stages; medulla is vascular loose connective tissue",
                    connections: "Connected to oviduct via fimbriae; suspended by mesovarium (part of broad ligament); receives blood from ovarian artery (branch of abdominal aorta)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Oviduct",
                    aliases: ["Fallopian tube", "Uterine tube", "Salpinx"],
                    function: "Transports ova from ovary to uterine horn; site of fertilization; cilia and peristalsis move the egg/embryo toward the uterus",
                    commonConfusions: ["Much shorter and more coiled in pigs than humans", "The infundibulum (funnel-shaped opening) catches the released ovum — it does NOT directly connect to the ovary"],
                    examTips: ["Practical ID: thin, highly coiled tube leading from ovary to horn of uterus; the most coiled structure in the female reproductive tract", "Fertilization occurs here (ampulla region), not in the uterus", "Infundibulum = open funnel end near ovary; isthmus = narrow end near uterus"],
                    histology: "Simple columnar epithelium with ciliated and secretory (peg) cells; cilia beat toward the uterus to propel the ovum",
                    connections: "Proximal: infundibulum opens near ovary; distal: connects to horn of uterus; suspended by mesosalpinx",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Horn of Uterus",
                    aliases: ["Uterine horn", "Cornu uteri"],
                    function: "Receives fertilized eggs from oviducts; houses individual fetuses during gestation in litter-bearing animals; each horn can contain multiple fetuses",
                    commonConfusions: ["Pigs have a bicornuate uterus — two long horns joining at the body; humans have a simplex uterus with no horns", "The horns are what make the pig uterus Y-shaped overall"],
                    examTips: ["Practical ID: long, convoluted tube-like structures extending from each side of the uterine body toward the oviducts", "In pregnant pigs, fetuses are strung along the horns like beads on a string", "Each horn can be 1–1.5 meters long in an adult sow"],
                    histology: "Endometrium (simple columnar epithelium with uterine glands), myometrium (smooth muscle layers), perimetrium (serosa)",
                    connections: "Proximal: connects to oviduct; distal: merges into body of uterus; broad ligament suspends it from body wall",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Body of Uterus",
                    aliases: ["Uterine body", "Corpus uteri"],
                    function: "Joins the two uterine horns; connects to the cervix; short in pigs compared to the long horns",
                    commonConfusions: ["In pigs the uterine body is relatively short compared to the long horns — don't confuse with the human simplex uterus where the body is the main structure"],
                    examTips: ["Practical ID: short, thick tubular structure where the two uterine horns merge before narrowing into the cervix", "Much shorter than each uterine horn in pigs"],
                    histology: "Same three layers as horns: endometrium (simple columnar + glands), myometrium (smooth muscle), perimetrium (serosa)",
                    connections: "Cranial: two uterine horns join here; caudal: narrows into cervix",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Cervix",
                    aliases: ["Uterine cervix", "Cervix uteri"],
                    function: "Muscular gateway between uterus and vagina; produces mucus plug to seal the uterus during pregnancy; dilates during labor for parturition",
                    commonConfusions: ["Pig cervix has a distinctive interlocking ridge pattern on the inner wall (annular folds) — different from most other species", "Do not confuse with the firm-walled vagina; the cervix is thicker-walled with obvious ridges"],
                    examTips: ["Practical ID: firm, ridged (annular ridged) tubular structure between uterine body and vagina", "The annular folds in pigs interdigitate to lock sperm-depositing semen — pigs are intrauterine depositors", "Acts as a barrier to infection during pregnancy"],
                    histology: "Dense fibromuscular connective tissue with simple columnar (mucus-secreting) epithelium in the endocervix; stratified squamous epithelium at the ectocervix",
                    connections: "Cranial end: uterine body; caudal end: vagina",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Vagina",
                    aliases: ["Birth canal"],
                    function: "Receives the penis during copulation (though in pigs semen is deposited directly into the uterus through the cervix); serves as the birth canal during parturition",
                    commonConfusions: ["In pigs, the vagina is shorter than in humans relative to the cervix", "The vagina opens into the urogenital sinus, not directly to the exterior in the fetal pig"],
                    examTips: ["Practical ID: large-diameter, thin-walled tube caudal to the cervix, leading toward the urogenital sinus", "Distinguished from rectum by its more ventral position and connection to urogenital sinus", "In pigs, sperm are deposited past the vagina into the cervix/uterus — the vagina is mainly a birth canal"],
                    histology: "Stratified squamous epithelium (nonkeratinized) — resistant to friction and abrasion; no glands in vaginal wall itself",
                    connections: "Cranial: cervix; caudal: urogenital sinus; dorsal to urethra",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Urethra",
                    aliases: ["Female urethra"],
                    function: "Carries urine from the urinary bladder to the urogenital sinus for elimination; does NOT carry reproductive products in females",
                    commonConfusions: ["In male pigs the urethra carries both urine and semen; in females it carries only urine", "The urethra opens into the urogenital sinus, where it meets the vagina"],
                    examTips: ["Practical ID: short tube running from the bladder ventrally, opening into the floor of the urogenital sinus", "Much shorter in females than in males", "The female urethral opening (urethral orifice) is on the ventral floor of the urogenital sinus"],
                    histology: "Transitional epithelium near bladder, transitioning to stratified squamous epithelium near the external opening",
                    connections: "Proximal: urinary bladder; distal: urogenital sinus; runs ventral to vagina",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Urogenital Sinus",
                    aliases: ["Urogenital vestibule", "Common urogenital opening"],
                    function: "Common chamber that receives both the vagina (reproductive) and the urethra (urinary) before opening to the exterior; unique shared opening in many non-primate mammals",
                    commonConfusions: ["Not present in adult humans — in humans, the urogenital sinus separates completely into distinct vaginal and urethral openings during development", "Do not confuse with the vulva, which is the external opening; the urogenital sinus is internal"],
                    examTips: ["Practical ID: chamber just inside the vulva where the vagina and urethra both open", "The fact that pigs (and many mammals) have a urogenital sinus instead of separate openings is a key species difference from humans", "In dissection, cut open the urogenital sinus to find both urethral and vaginal orifices"],
                    histology: "Stratified squamous epithelium lining the common chamber",
                    connections: "Receives vagina (dorsal/cranial) and urethra (ventral); opens to exterior at vulva",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Vulva",
                    aliases: ["External genitalia", "External urogenital opening"],
                    function: "External opening of the female urogenital system; includes the labia and the external opening of the urogenital sinus",
                    commonConfusions: ["The vulva is the external visible opening; it opens into the urogenital sinus internally", "Do not confuse vulva (external) with vagina (internal canal)"],
                    examTips: ["Practical ID: visible external slit-like opening on the ventral surface caudal to the anus", "In fetal pigs, the vulva is located ventral to the anus — opposite of males where the scrotal sac/penis is located", "The genital papilla (small projection) is sometimes visible near the vulva"],
                    histology: "Stratified squamous epithelium (keratinized on outer skin surface, nonkeratinized internally)",
                    connections: "External opening of urogenital sinus; located caudal to anus on the perineum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: femaleRepCat.id,
                    name: "Genital Papilla",
                    aliases: ["Urogenital papilla", "Clitoral papilla"],
                    function: "Small erectile projection near the urogenital opening; homologous to the penis in males; helps identify sex in fetal pigs",
                    commonConfusions: ["The genital papilla in females is much smaller than the male urogenital papilla/penis and does not have a urethral opening on it like the male", "In fetal pigs, the genital papilla is the easiest external sex determination landmark"],
                    examTips: ["KEY SEX DETERMINATION: females have a smaller genital papilla located just ventral to the anus/vulva", "Males have a larger urogenital papilla (penile projection) with the urethral opening at its tip — located farther from the anus", "The tail-to-papilla distance is greater in males than females — females' papilla is right near the anus"],
                    histology: "Stratified squamous epithelium overlying erectile (vascular) connective tissue",
                    connections: "Near vulva; homologous to male penile shaft",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Fetal Structures
        if let fetalCat = categories.first(where: { $0.name == "Fetal Structures" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Allantois",
                    aliases: ["Allantoic membrane", "Allantoic sac"],
                    function: "Extraembryonic membrane that collects fetal urine (waste); contributes to formation of the placenta (chorioallantoic placenta); vascularized — carries fetal blood vessels to the placenta",
                    commonConfusions: ["Allantois vs amnion: allantois is the outer membrane involved in gas/waste exchange; amnion is the innermost membrane directly surrounding the fetus", "In pigs, allantois is very large compared to other species because of their diffuse epitheliochorial placenta"],
                    examTips: ["Practical ID: large fluid-filled sac surrounding the amnion; appears bluish or milky in preserved specimens", "In pigs, the allantoic sac can be larger than the amniotic sac", "Contains allantoic fluid (fetal urine) — not to be confused with amniotic fluid which surrounds the fetus directly"],
                    histology: "Simple cuboidal to transitional epithelium lining; outer surface is vascularized mesoderm fusing with chorion",
                    connections: "Fuses with chorion to form chorioallantoic membrane; connects to fetal bladder via urachus (allantoic stalk); lines the inside of the chorion",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Chorion",
                    aliases: ["Chorionic membrane", "Outer fetal membrane"],
                    function: "Outermost extraembryonic membrane; in pigs it fuses with the allantois to form the chorioallantoic membrane that interfaces with the maternal uterine lining for gas/nutrient exchange",
                    commonConfusions: ["Chorion vs amnion: chorion is the outermost fetal membrane; amnion is innermost", "In pigs, the chorion does NOT penetrate the uterine wall (diffuse epitheliochorial placenta) — contrast with humans where chorionic villi invade maternal tissue (hemochorial placenta)"],
                    examTips: ["Practical ID: outermost membranous sac when the fetal membranes are intact; surrounds all other membranes", "Pig placenta type: diffuse epitheliochorial — chorionic villi interdigitate with uterine folds but do NOT invade maternal blood vessels", "This explains why sows can reabsorb fetuses without hemorrhage"],
                    histology: "Trophoblast-derived epithelium covering fetal mesoderm; in pigs it forms chorionic villi that interdigitate with endometrial folds (areolae)",
                    connections: "Outermost layer; fuses with allantois on inner side; outer surface contacts uterine endometrium",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Amnion",
                    aliases: ["Amniotic membrane", "Inner fetal membrane"],
                    function: "Innermost extraembryonic membrane; encloses the fetus in amniotic fluid which cushions, protects from desiccation, allows movement, and maintains temperature",
                    commonConfusions: ["Amnion (inner, surrounds fetus in amniotic fluid) vs allantois (outer, collects waste) vs chorion (outermost)", "Amniotic fluid is produced by the fetus (fetal urine + lung secretions later) — not the same as allantoic fluid"],
                    examTips: ["Practical ID: thin, clear innermost membrane directly touching/surrounding the fetal pig body", "Amniotic fluid serves as a shock absorber — important for fetal movement and lung development", "The 'water bag' that breaks at birth is the amnion releasing amniotic fluid"],
                    histology: "Simple squamous to simple cuboidal amniotic epithelium overlying avascular mesoderm (no blood vessels in amnion itself)",
                    connections: "Directly surrounds fetus; inner to allantois; contains amniotic fluid; continuous with fetal skin at umbilicus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Chorionic Vesicle",
                    aliases: ["Gestational sac", "Chorionic sac"],
                    function: "The earliest embryonic structure visible by ultrasound; represents the fluid-filled cavity of the chorion in early pregnancy before placental development is complete",
                    commonConfusions: ["Not a permanent structure — the chorionic vesicle is an early embryonic stage that develops into the more organized chorioallantoic membrane system"],
                    examTips: ["Early embryonic landmark; in very young fetal pig specimens you may see small chorionic vesicles before the fetal membranes are fully differentiated", "In pigs multiple chorionic vesicles line up in each uterine horn, one per fetus"],
                    histology: "Chorionic trophoblast epithelium surrounding fluid-filled extraembryonic cavity (exocoelom)",
                    connections: "Contains embryo + yolk sac early on; later the allantois grows out to fuse with it; located within uterine horn",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Ductus Venosus",
                    aliases: ["Fetal venous shunt", "Arantius' duct"],
                    function: "Fetal shunt that bypasses the liver: carries oxygenated blood from the umbilical vein directly to the inferior vena cava, allowing most of the richly oxygenated blood from the placenta to go directly to the heart rather than being filtered by the liver",
                    commonConfusions: ["One of THREE fetal shunts: ductus venosus (liver bypass), foramen ovale (right-to-left atrial shunt), ductus arteriosus (pulmonary bypass)", "After birth it closes and becomes the ligamentum venosum (fibrous remnant in liver)"],
                    examTips: ["Mnemonic for three shunts: 'DVD' — Ductus Venosus, foramen oVale, Ductus arteriosus", "Ductus venosus → ligamentum venosum (post-birth remnant)", "Closes within days of birth as umbilical flow ceases — functional closure is rapid, anatomical closure takes weeks"],
                    histology: "Thin-walled venous shunt with endothelial lining; smooth muscle in wall allows active regulation",
                    connections: "Receives: umbilical vein; drains into: inferior vena cava (at junction with hepatic veins); bypasses hepatic sinusoids",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Fetus",
                    aliases: ["Fetal pig", "Developing pig", "Fetal specimen"],
                    function: "The developing pig contained within the fetal membranes; completely dependent on placental exchange and fetal circulatory shunts since the lungs are nonfunctional and independent feeding is absent; the fetus receives O2 and nutrients from the mother via the umbilical vein and returns CO2/waste via the umbilical arteries",
                    commonConfusions: ["Fetal circulation differs from adult: lungs are bypassed by ductus arteriosus; liver is partly bypassed by ductus venosus; oxygenated blood crosses from right to left atrium via foramen ovale", "The fetus is enclosed in amnion (innermost) → allantois → chorion (outermost); when you open the chorionic vesicle you encounter these membranes before reaching the fetus"],
                    examTips: ["On the fetal membrane diagram, the fetus is the labeled central structure enclosed by all the membrane layers", "KEY developmental physiology: three fetal shunts — ductus venosus (bypasses liver), foramen ovale (bypasses lungs at atrial level), ductus arteriosus (bypasses lungs at vessel level)", "Fetal blood oxygenation: placenta → umbilical vein → (partly via ductus venosus bypassing liver) → caudal vena cava → right atrium → foramen ovale → left atrium → left ventricle → aorta → body"],
                    histology: "The fetus itself is not a tissue type; it is the whole organism. Its organs are developing but histologically similar to postnatal structures.",
                    connections: "Surrounded by: amnion → allantois → chorion → uterine wall; connected to placenta via umbilical cord (containing 2 umbilical arteries + 1 umbilical vein); enclosed within chorionic vesicle in uterine horn",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Maternal Vessels in Uterine Lining",
                    aliases: ["Maternal blood vessels", "Uterine vessels", "Maternal capillaries", "Maternal vessels"],
                    function: "The maternal blood vessels (arteries, capillaries, and veins) within the uterine endometrium that deliver oxygenated, nutrient-rich blood to the placental exchange zone and drain deoxygenated, waste-carrying blood away; in pigs, the maternal and fetal blood never mix (epitheliochorial placenta type)",
                    commonConfusions: ["VERY IMPORTANT: in pigs, maternal and fetal blood do NOT mix — exchange occurs across 6 tissue layers (maternal capillary endothelium → maternal CT → uterine epithelium → chorionic epithelium → fetal CT → fetal capillary endothelium)", "Contrast with humans (hemochorial): human chorionic villi are bathed directly in maternal blood; pig chorion stays separated from maternal blood by multiple epithelial barriers"],
                    examTips: ["On the fetal membrane diagram, maternal vessels are labeled in the uterine wall/lining, on the maternal side of the placental interface", "The maternal vessels are the 'other side' of placental exchange from the fetal umbilical vessels within the allantoic membrane", "KEY EXAM CONCEPT: the 6-layer epitheliochorial placental barrier means fetal and maternal blood are separated — this is why pig placenta is called 'non-invasive'"],
                    histology: "Maternal vessels are lined by simple squamous endothelium (like all blood vessels); they are embedded in uterine connective tissue (endometrial stroma); the overlying uterine epithelium remains intact and does NOT break down (unlike humans)",
                    connections: "Located in uterine endometrium; supplied by uterine arteries (from internal iliac); drain into uterine veins; adjacent to uterine glands (which open at areolae); on maternal side of placental interface facing chorionic surface",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: fetalCat.id,
                    name: "Areolae",
                    aliases: ["Chorionic areolae", "Uterine areolae"],
                    function: "Round bumps on the surface of the chorion adjacent to uterine glands; absorb 'histotroph' (uterine milk) — a nutrient-rich secretion of proteins, sugars, lipids, ions, and growth factors from the uterine glands that provides fetal nutrition at the epitheliochorial placental interface",
                    commonConfusions: ["Areolae (chorionic bumps absorbing uterine milk) vs the nipple areola — these are completely different structures with only a naming similarity", "Areolae are visible on the chorion as small, rounded projections adjacent to uterine gland openings"],
                    examTips: ["KEY CONCEPT for pig placenta: pig fetuses receive nutrition two ways — 1) hemotrophic (via chorioallantoic blood vessels) and 2) histotrophic (areolae absorbing uterine gland secretions)", "Practical ID: look for small round bumps on the chorionic surface of the placenta — these are the areolae", "The fact that pigs use both hemotrophic + histotrophic nutrition is unusual and reflects their non-invasive epitheliochorial placenta type"],
                    histology: "Areolae are specialized trophoblast cells overlying the uterine gland openings; cuboidal/columnar cells with absorptive microvilli for uptake of histotroph",
                    connections: "Located on chorion surface opposite uterine gland openings; adjacent to the chorioallantoic vascular network",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Adult Maternal Pig
        if let maternalCat = categories.first(where: { $0.name == "Adult Maternal Pig" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Uterus (Adult Maternal)",
                    aliases: ["Sow uterus", "Gravid uterus", "Adult pig uterus"],
                    function: "Houses and nourishes multiple fetuses simultaneously; the enormously enlarged bicornuate uterus of a pregnant sow shows the extreme capacity of the pig reproductive system — a sow can carry 8–14+ piglets",
                    commonConfusions: ["The adult sow uterus dwarfs the fetal pig uterus — the horns can be 1–1.5 m long and filled with fetuses", "Different from a human uterus: pig uterus is bicornuate (two horns) vs human simplex (no horns)"],
                    examTips: ["At the adult station, identify: the two long uterine horns (cornu uteri), the short uterine body, and the cervix", "The fetuses seen through the uterine wall are in the horns — count how many fit per horn", "The diffuse epitheliochorial pig placenta means fetuses attach all along the horn interior via chorionic villi"],
                    histology: "Endometrium expanded during pregnancy: tall columnar epithelium with enlarged uterine glands (areolae) secreting uterine milk (histotroph) to nourish fetuses at the epitheliochorial interface",
                    connections: "Horns connect to oviducts cranially; body connects to cervix caudally; supplied by uterine artery (from internal iliac); broad ligament suspends it",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Placenta",
                    aliases: ["Pig placenta", "Diffuse epitheliochorial placenta", "Chorioallantoic placenta"],
                    function: "Organ of exchange between fetal and maternal circulation for O2, CO2, nutrients, and waste products; in pigs it is diffuse epitheliochorial — the least invasive placental type among mammals",
                    commonConfusions: ["Pig placenta type: DIFFUSE (covers entire chorion surface, not a discrete disc) and EPITHELIOCHORIAL (6 tissue layers between fetal and maternal blood — chorion | connective tissue | fetal blood | maternal blood | connective tissue | uterine epithelium)", "Human placenta is hemochorial (3 layers) — chorionic villi invade all the way to maternal blood; pig placenta keeps all 6 layers intact"],
                    examTips: ["KEY EXAM CONCEPT: pig placenta classification = diffuse epitheliochorial", "Diffuse = spread over whole uterine horn interior, not localized (contrast: humans = discoid, cows = cotyledonary)", "Epitheliochorial = least invasive; maternal and fetal epithelia remain intact and just interdigitate", "Because of this, pigs must compensate with enormous chorion surface area (long horns) and specialized uterine gland secretions (histotroph/uterine milk)"],
                    histology: "Six-layer barrier (from fetal to maternal side): fetal capillary endothelium → fetal connective tissue → chorionic trophoblast epithelium → uterine epithelium → maternal connective tissue → maternal capillary endothelium",
                    connections: "Fetal side: chorioallantoic membrane; maternal side: uterine endometrium; umbilical cord connects fetus to placenta",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Fetal Membranes",
                    aliases: ["Afterbirth", "Extraembryonic membranes", "Placental membranes"],
                    function: "The three layered extraembryonic membranes (amnion, allantois, chorion) that surround each fetus and mediate fetal-maternal exchange; expelled after birth as the afterbirth",
                    commonConfusions: ["Each piglet in the litter is surrounded by its own set of fetal membranes, though the allantoic cavities of adjacent fetuses may fuse in pigs", "The fetal membranes are NOT the placenta — they form the fetal side; the maternal side is the uterine endometrium"],
                    examTips: ["At the adult station you may see intact fetal membrane packets around individual fetuses within the uterine horn", "Order from inside to outside around the fetus: amnion (innermost) → allantois → chorion (outermost)", "After birth, failure to expel fetal membranes (retained placenta) is a veterinary emergency in sows"],
                    histology: "Amnion: avascular simple epithelium; Allantois: cuboidal epithelium + vascularized mesoderm; Chorion: trophoblast epithelium with chorionic villi",
                    connections: "Amnion surrounds fetus directly; allantois connects to fetal bladder via urachus; chorion contacts uterine wall; all three connect at umbilicus",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Uterine Artery",
                    aliases: ["Uterine arteries", "Arteria uterina"],
                    function: "Major blood supply to the pregnant uterus; dramatically enlarges during pregnancy to deliver massive blood flow to support all the fetuses simultaneously",
                    commonConfusions: ["In pigs, the uterine artery is a branch of the internal iliac artery (not the aorta directly)", "The uterine artery travels in the broad ligament to reach the uterus"],
                    examTips: ["At the adult station, identify the large, highly coiled uterine arteries running along the sides of the gravid uterine horns within the broad ligament", "The dramatic enlargement and coiling of the uterine artery during pregnancy (vs non-pregnant state) is visually striking", "Supplies the myometrium and endometrium via arcuate → radial → spiral arteries"],
                    histology: "Thick-walled muscular artery (tunica intima, media with smooth muscle, adventitia); enlarges significantly during pregnancy under estrogen/progesterone influence",
                    connections: "Origin: internal iliac artery; travels in mesometrium (part of broad ligament); branches to supply uterine horn wall; anastomoses with ovarian artery at cranial horn",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Ovary (Adult)",
                    aliases: ["Adult sow ovary", "Mature ovary"],
                    function: "In non-pregnant adult sows: site of follicle development, ovulation, and corpus luteum formation for progesterone secretion; in pregnant sows: the corpora lutea remain active throughout pregnancy maintaining progesterone levels (unlike humans where the placenta takes over)",
                    commonConfusions: ["Adult pig ovary looks very different from fetal pig ovary: adult ovaries have large visible follicles and/or corpora lutea (bumpy surface), while fetal ovaries are small and smooth", "Pig corpora lutea persist throughout pregnancy — the pig is corpus luteum-dependent for progesterone for the entire 114-day gestation"],
                    examTips: ["At the adult station: look for large, bumpy ovaries with visible follicles (fluid-filled spheres) or corpora lutea (solid yellowish structures)", "Corpora lutea = 'yellow bodies' — remnants of follicles after ovulation; appear as solid, yellowish nodules on ovary surface", "If you see multiple large corpora lutea, the sow likely had a recent pregnancy or was recently cycling"],
                    histology: "Cortex: granulosa and theca cells of follicles; after ovulation, granulosa cells luteinize → corpus luteum (large steroidogenic cells with lipid droplets); medulla: vascular loose connective tissue",
                    connections: "Suspended by mesovarium; ovarian artery from abdominal aorta; ovarian vein to renal vein (left) or IVC (right); oviduct fimbriae draped over surface",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: maternalCat.id,
                    name: "Broad Ligament",
                    aliases: ["Mesometrium", "Broad ligament of uterus"],
                    function: "Sheet of peritoneum that suspends the uterus, oviducts, and ovaries from the dorsal body wall; contains blood vessels, lymphatics, and nerves traveling to the reproductive organs",
                    commonConfusions: ["The broad ligament is NOT a true ligament (not dense collagenous tissue) — it is a double fold of peritoneum", "Contains three named parts: mesovarium (suspends ovary), mesosalpinx (suspends oviduct), mesometrium (suspends uterus)"],
                    examTips: ["Practical ID at adult station: large fan-like sheet of tissue suspending the entire reproductive tract from the dorsal abdominal wall", "The uterine artery and ovarian vessels run within the broad ligament to reach the uterus/ovary", "Tearing the broad ligament during dissection reveals its layers and the vessels contained within"],
                    histology: "Double layer of simple squamous peritoneal epithelium (mesothelium) with loose connective tissue, smooth muscle, blood vessels, lymphatics between the layers",
                    connections: "Attaches reproductive tract to dorsal pelvic/abdominal wall; mesovarium → ovary; mesosalpinx → oviduct; mesometrium → uterine horn and body",
                    highYield: false
                ),
            ])
        }
        
        // MARK: Cow Eye
        if let eyeCat = categories.first(where: { $0.name == "Cow Eye" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Cornea",
                    aliases: ["Transparent anterior covering"],
                    function: "Protects the eye; allows light entry; major contributor to light refraction/focusing",
                    commonConfusions: ["Corneal epithelium is nonkeratinized unlike skin — must remain transparent; organized collagen and absence of blood vessels are required for transparency"],
                    examTips: ["Not actually tested on the practical even though it was on the study list", "Practical ID: clear dome-like anterior surface of eye"],
                    histology: "Stratified squamous epithelium (nonkeratinized) — nonkeratinized to maintain transparency; exposed externally, vulnerable to abrasion, needs rapid repair capability",
                    connections: "Anterior eye surface; transitions to sclera at limbus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Choroid",
                    aliases: ["Choroidal layer", "Choroid layer"],
                    function: "Supplies blood to the retina; absorbs stray light; supports photoreceptor metabolism — rich vascular supply is critical for highly metabolically active retina",
                    commonConfusions: [],
                    examTips: ["Practical ID: dark pigmented layer deep to sclera", "Tapetum lucidum is associated with the choroid layer — very important for practical ID"],
                    histology: "Vascular connective tissue containing blood vessels, connective tissue, and pigment cells",
                    connections: "Between sclera and retina; associated with tapetum lucidum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Vitreous Body",
                    aliases: ["Vitreous humor", "Vitreous gel"],
                    function: "Maintains eyeball shape; supports retina; transmits light",
                    commonConfusions: [],
                    examTips: ["Practical ID: clear jelly-like substance filling posterior eye cavity"],
                    images: [ImageCDN.image("vitreous-body_gross_1.jpg", caption: "Vitreous Body")],
                    histology: "Gel-like extracellular material with very few cells and high water content",
                    connections: "Fills posterior chamber behind lens",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Retina",
                    aliases: ["Neural retina", "Retinal layer"],
                    function: "Converts light into neural signals — the actual sensory layer of the eye",
                    commonConfusions: [],
                    examTips: ["WAS tested on the practical", "Practical ID: thin delicate layer peeling from inside posterior eye", "Contains rods and cones (photoreceptors) that detect light", "Signal path: retina → optic nerve → brain"],
                    histology: "Nervous tissue (NOT epithelial) — contains photoreceptors (rods and cones), bipolar neurons, ganglion cells, and glial support cells",
                    connections: "Receives light from lens/vitreous; connects to optic nerve at optic disk",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Lens",
                    aliases: ["Crystalline lens", "Ocular lens"],
                    function: "Focuses light onto retina; changes shape for accommodation controlled by ciliary body/muscle",
                    commonConfusions: ["Lacks blood vessels and pigmentation to maintain optical clarity"],
                    examTips: ["WAS tested on the practical", "Practical ID: firm clear spherical/biconvex structure in center of eye"],
                    histology: "Avascular transparent structure; highly organized lens fibers without nuclei in mature cells",
                    connections: "Posterior to iris/pupil; anterior to vitreous body; attached to ciliary body via suspensory ligaments",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Pupil",
                    aliases: ["Pupillary opening", "Pupillary aperture"],
                    function: "Controls how much light enters the eye; light path: cornea → pupil → lens → retina",
                    commonConfusions: ["VERY IMPORTANT: the pupil is NOT tissue — it is simply an opening/aperture in the iris"],
                    examTips: ["Practical ID: dark opening in center of iris", "Pupil size is controlled by iris smooth muscle"],
                    histology: "Not a tissue — an opening in the iris",
                    connections: "Opening in center of iris; part of the light pathway to the retina",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Iris",
                    aliases: ["Iris diaphragm", "Colored eye ring"],
                    function: "Controls pupil diameter via constriction and dilation to regulate light entry",
                    commonConfusions: [],
                    examTips: ["Practical ID: colored ring surrounding pupil", "Contains circular muscles (constrict pupil) and radial muscles (dilate pupil)"],
                    histology: "Contains smooth muscle, pigment cells, connective tissue, and vessels — pigmentation reduces stray light scattering",
                    connections: "Surrounds pupil; anterior to lens",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Ciliary Body",
                    aliases: ["Ciliary muscle", "Ciliary ring"],
                    function: "Controls lens shape for accommodation; produces aqueous humor",
                    commonConfusions: [],
                    examTips: ["WAS tested on the practical", "Practical ID: thickened structure surrounding lens", "Smooth muscle alters lens tension through suspensory ligaments"],
                    histology: "Contains smooth muscle, connective tissue, vascular tissue, and secretory epithelium — muscular organization allows accommodation; secretory tissue produces aqueous humor",
                    connections: "Near lens attachment; connected to lens via suspensory ligaments",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Optic Disk",
                    aliases: ["Optic disc", "Blind spot", "Optic papilla"],
                    function: "Point where optic nerve exits the retina; transmits retinal ganglion cell axons into optic nerve",
                    commonConfusions: ["VERY IMPORTANT: this region lacks photoreceptors — it is the blind spot"],
                    examTips: ["Practical ID: small circular region where optic nerve attaches internally"],
                    histology: "Nerve fiber convergence point; no photoreceptors present",
                    connections: "Where retina connects to optic nerve",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Sclera",
                    aliases: ["White of the eye", "Sclerotic coat"],
                    function: "Protects eye; maintains eyeball shape; provides muscle attachment",
                    commonConfusions: [],
                    examTips: ["WAS tested on the practical", "Practical ID: tough white outer wall of eyeball"],
                    histology: "Dense fibrous connective tissue rich in collagen fibers — dense collagen provides strength and rigidity",
                    connections: "Outer coat of eyeball; transitions to cornea anteriorly",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Tapetum Lucidum",
                    aliases: ["Reflective layer", "Eye shine layer"],
                    function: "Enhances night vision by reflecting light back through the retina — gives photoreceptors a second chance to detect photons",
                    commonConfusions: ["Humans have NO tapetum lucidum; it is present in many other mammals — important comparative concept"],
                    examTips: ["WAS tested — one of the more recognizable cow-eye structures", "Practical ID: shiny blue-green reflective layer inside posterior eye", "Located within/specialized from choroid region"],
                    histology: "Specialized reflective connective tissue within the choroid; contains crystalline reflective structures",
                    connections: "Within choroid layer; posterior eye",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: eyeCat.id,
                    name: "Optic Nerve",
                    aliases: ["Cranial nerve II", "CN II"],
                    function: "Carries visual information from retina to brain",
                    commonConfusions: [],
                    examTips: ["NOT tested on this practical according to exam breakdown, but was on study list", "Practical ID: cord-like structure exiting posterior eyeball", "Signal path: retina → optic nerve → optic chiasm → brain visual cortex"],
                    histology: "Nervous tissue containing axons, glial support tissue (oligodendrocytes, astrocytes), and connective tissue sheaths (meninges)",
                    connections: "Retina → optic nerve → optic chiasm → brain",
                    highYield: false
                ),
            ])
        }
        
        // MARK: Blood Histology
        if let bloodHistologyCat = categories.first(where: { $0.name == "Blood Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Erythrocyte",
                    aliases: ["Red blood cell", "RBC"],
                    function: "Transports oxygen",
                    examTips: ["Most numerous blood cell"],
                    images: [ImageCDN.slide("erythrocyte_histo_1.jpeg", magnification: 10, caption: "Blood Smear — Erythrocytes 10×")],
                    histology: "Biconcave disc; lacks nucleus in mammals"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Platelet",
                    aliases: ["Thrombocyte"],
                    function: "Initiates blood clotting",
                    examTips: ["Involved in hemostasis"],
                    images: [ImageCDN.slide("erythrocyte_histo_1.jpeg", magnification: 10, caption: "Blood Smear — Platelets visible among erythrocytes 10×")],
                    histology: "Small cell fragment"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Lymphocyte",
                    aliases: ["Agranular WBC"],
                    function: "Immune response; produces antibodies",
                    examTips: ["T cells and B cells"],
                    histology: "Large nucleus; minimal cytoplasm"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Monocyte",
                    aliases: ["Agranulocyte"],
                    function: "Precursor to macrophages",
                    examTips: ["Becomes macrophage in tissues"],
                    images: [ImageCDN.slide("monocyte_histo_1.jpg", magnification: 40, caption: "Monocyte — 40×")],
                    histology: "Largest white blood cell; kidney-shaped nucleus"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Neutrophil",
                    aliases: ["PMN", "Segmented neutrophil"],
                    function: "Phagocytoses bacteria",
                    examTips: ["Most abundant white blood cell"],
                    images: [ImageCDN.slide("neutrophil_histo_1.jpg", magnification: 40, caption: "Neutrophil — 40×")],
                    histology: "Multilobed nucleus; granular"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Eosinophil",
                    aliases: ["Acidophil"],
                    function: "Responds to parasites and allergies",
                    examTips: ["Pink-staining granules"],
                    histology: "Bilobed nucleus; acidophilic granules"
                ),
                AnatomyStructure(
                    categoryId: bloodHistologyCat.id,
                    name: "Basophil",
                    aliases: ["Mast cell"],
                    function: "Releases histamine in allergic responses",
                    examTips: ["Least common white blood cell"],
                    histology: "Basophilic granules; obscure nucleus"
                ),
            ])
        }
        
        // MARK: Vessel Histology
        if let vesselHistologyCat = categories.first(where: { $0.name == "Vessel Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Tunica Intima",
                    aliases: ["Inner lining"],
                    function: "Innermost layer; provides smooth surface",
                    examTips: ["Reduces friction with blood"],
                    histology: "Simple squamous endothelium"
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Tunica Media",
                    aliases: ["Middle layer"],
                    function: "Provides elasticity and contraction",
                    examTips: ["Thicker in arteries than veins"],
                    histology: "Smooth muscle and elastic tissue"
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Tunica Adventitia",
                    aliases: ["Outer layer"],
                    function: "Structural support",
                    examTips: ["Anchors vessel in place"],
                    histology: "Connective tissue"
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Artery",
                    aliases: ["Arterial vessel"],
                    function: "Carries blood away from heart",
                    examTips: ["Thicker walls than veins"],
                    images: [ImageCDN.slide("artery-vein-nerve_histo_artery_1.jpeg", magnification: 10, caption: "Artery")],
                    histology: "Thick muscular wall; small lumen"
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Vein",
                    aliases: ["Venous vessel"],
                    function: "Returns deoxygenated blood to the heart at low pressure",
                    commonConfusions: ["Vein vs artery on slides: vein has thinner wall relative to lumen, often irregular/collapsed lumen; artery has thicker wall, rounder lumen", "Vein wall is thinner because blood pressure in veins is much lower than arteries"],
                    examTips: ["Key ID vs artery: vein has proportionally LARGER lumen and THINNER wall (less smooth muscle in tunica media)", "Veins often appear collapsed or irregular in shape on slides (not perfectly round like arteries)", "Still has three tunica layers but media is much thinner"],
                    images: [ImageCDN.slide("artery-vein-nerve_histo_vein_1.jpeg", magnification: 10, caption: "Vein")],
                    histology: "Tunica intima (simple squamous endothelium), thin tunica media (sparse smooth muscle), tunica adventitia (thickest layer, dense connective tissue)",
                    connections: "Systemic veins return to right heart; pulmonary veins return to left heart; venules → small veins → larger veins → vena cava",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Aorta",
                    aliases: ["Human aorta", "Elastic artery"],
                    function: "Largest artery in the body; carries oxygenated blood from the left ventricle to the systemic circulation; its elastic walls stretch during systole and recoil during diastole to maintain continuous flow",
                    commonConfusions: ["Aorta is an elastic artery — its tunica media is dominated by elastic laminae (not just smooth muscle like muscular arteries)", "On the slide: the aorta wall appears thick with wavy pink elastic lamellae in the media — very different from the muscular artery on the artery/vein/nerve slide"],
                    examTips: ["KEY ID: thick wall with abundant wavy elastic lamellae in tunica media = elastic artery (aorta)", "The aorta wall is so thick it has its own blood vessels (vasa vasorum) within the adventitia to nourish the outer wall layers", "Compare: aorta (elastic) vs. smaller artery (muscular) — aorta has more elastic tissue, muscular artery has more smooth muscle in media"],
                    histology: "Tunica intima: endothelium + subendothelial connective tissue + internal elastic lamina; tunica media: many layers of elastic lamellae alternating with smooth muscle (elastic artery type); tunica adventitia: dense irregular connective tissue with vasa vasorum",
                    connections: "Ascends from left ventricle → aortic arch (gives off brachiocephalic, left common carotid, left subclavian) → descending thoracic aorta → abdominal aorta → bifurcates into common iliac arteries",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Vena Cava",
                    aliases: ["Human vena cava", "Large vein"],
                    function: "Largest veins; return deoxygenated blood to the right atrium; cranial (superior) vena cava drains head/neck/arms; caudal (inferior) vena cava drains abdomen/legs",
                    commonConfusions: ["Vena cava vs aorta on slides: both are large vessels, but vena cava has thinner wall relative to its lumen and less elastic tissue in the media", "The vena cava adventitia is proportionally the thickest layer (unlike arteries where media dominates)"],
                    examTips: ["KEY ID: very large lumen, thin wall relative to lumen size, adventitia is the thickest layer = vena cava", "On the slide: the wall looks collapsed or irregular because the low-pressure venous blood doesn't keep it fully distended", "The vena cava has some smooth muscle bundles longitudinally in the adventitia — unusual for veins"],
                    histology: "Tunica intima: simple squamous endothelium; tunica media: thin, sparse smooth muscle and elastic fibers; tunica adventitia: very thick, dense connective tissue with longitudinal smooth muscle bundles; overall wall much thinner relative to lumen than aorta",
                    connections: "Cranial vena cava: drains SVC territory → right atrium; caudal vena cava: drains IVC territory (kidneys, liver, lower limbs) → right atrium",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: vesselHistologyCat.id,
                    name: "Nerve",
                    aliases: ["Peripheral nerve", "Nerve bundle", "Nerve fascicle"],
                    function: "Transmits electrical signals (action potentials) between body regions; peripheral nerves carry motor commands to muscles and sensory information from receptors to the CNS",
                    commonConfusions: ["On the artery/vein/nerve slide: nerve has NO hollow lumen (unlike vessels); it consists of bundled fascicles of axons — look for the 'telephone cable' cross-section appearance", "Nerve vs blood vessel: vessels have clear hollow lumens; nerve is solid bundled tissue with no lumen"],
                    examTips: ["KEY ID on the artery/vein/nerve slide — three structures side by side: artery (thick round wall, round lumen), vein (thin wall, irregular lumen), nerve (NO lumen, bundled fascicles)", "Nerve cross-section looks like a 'bundle of cables': multiple fascicles each containing many small round axons, surrounded by connective tissue sheaths", "Epineurium = outermost connective tissue around whole nerve; perineurium = around each fascicle; endoneurium = around each axon"],
                    images: [ImageCDN.slide("artery-vein-nerve_histo_nerve_1.jpeg", magnification: 10, caption: "Nerve")],
                    histology: "Nervous tissue: axons (nerve fibers) bundled into fascicles; each axon may be myelinated (myelin sheath = white fatty insulation) or unmyelinated; connective tissue sheaths: epineurium, perineurium, endoneurium",
                    connections: "Peripheral nerves branch from spinal cord/brain; travel with blood vessels in neurovascular bundles; artery/vein/nerve triad is a common anatomical arrangement in limbs and viscera",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Respiratory Histology
        if let respHistologyCat = categories.first(where: { $0.name == "Respiratory Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Sero-Mucous Glands",
                    aliases: ["Tracheal submucosal glands", "Serous-mucous glands", "Seromucous glands"],
                    function: "Mixed exocrine glands in the tracheal submucosa that produce both watery serous secretions and viscous mucus; together they humidify inhaled air, trap particulate matter and pathogens, and provide the fluid layer that the mucociliary escalator moves upward",
                    commonConfusions: ["Sero-mucous glands are in the SUBMUCOSA of the trachea, below the mucosa — not the same as goblet cells which are in the epithelium itself", "Sero-mucous = MIXED glands (both serous + mucous cells) — contrast with purely mucous glands or purely serous glands"],
                    examTips: ["Practical ID on trachea/esophagus slide: look DEEP to the tracheal epithelium, below the cartilage rings, for clusters of glandular tissue in the submucosa — these are the sero-mucous glands", "On the slide, the trachea shows (inside to out): pseudostratified columnar epithelium → submucosa WITH sero-mucous glands → tracheal cartilage → smooth muscle → adventitia", "The glands appear as clusters of pale (mucous) and darker (serous) secretory cells with small ducts"],
                    histology: "Mixed gland: serous acini (darker, small cells with dense granules) + mucous acini (pale, large vacuolated cells with mucin); surrounded by myoepithelial cells; ducts lined by cuboidal epithelium opening through the mucosa into the airway",
                    connections: "Located in tracheal submucosa; ducts open through the mucosa into the airway lumen; work with goblet cells (in epithelium) and cilia (on epithelial surface) to form the mucociliary defense system",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Tracheal Cartilage",
                    aliases: ["Hyaline cartilage rings"],
                    function: "Maintains airway patency",
                    examTips: ["Incomplete dorsally to allow esophageal expansion"],
                    histology: "Hyaline cartilage; C-shaped rings"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Alveoli",
                    aliases: ["Alveolar sacs"],
                    function: "Gas exchange sites",
                    examTips: ["Site of O2/CO2 exchange"],
                    histology: "Simple squamous epithelium"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Alveolar Sacs",
                    aliases: ["Terminal air pouches"],
                    function: "Clusters of alveoli",
                    examTips: ["Multiple alveoli per sac"],
                    histology: "Multiple alveoli opening into common chamber"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Bronchus",
                    aliases: ["Bronchial passage"],
                    function: "Conducts air to lungs",
                    examTips: ["Cartilage present in bronchi"],
                    histology: "Pseudostratified ciliated columnar; cartilage rings"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Bronchiole",
                    aliases: ["Small bronchus"],
                    function: "Smallest bronchial branch",
                    examTips: ["Connects to alveolar ducts"],
                    histology: "Pseudostratified ciliated columnar; no cartilage"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Respiratory Epithelium",
                    aliases: ["Pseudostratified ciliated columnar"],
                    function: "Air conditioning and defense",
                    examTips: ["VERY HIGH YIELD concept"],
                    histology: "Pseudostratified columnar with cilia and goblet cells"
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Pulmonary Smooth Muscle",
                    aliases: ["Bronchial smooth muscle"],
                    function: "Controls airway diameter via bronchoconstriction and bronchodilation; regulated by the autonomic nervous system (sympathetic = dilate; parasympathetic = constrict)",
                    commonConfusions: ["Smooth muscle in bronchioles is what causes asthma attacks (excessive bronchoconstriction)", "Pulmonary smooth muscle is in bronchioles, NOT in alveoli — alveoli have no smooth muscle"],
                    examTips: ["Practical ID on lung slide: smooth muscle appears as pink rings/bundles around bronchioles, inside the cartilage-free small airways", "More prominent in bronchioles (no cartilage) than bronchi (which have cartilage rings)"],
                    histology: "Smooth muscle (non-striated, spindle-shaped cells, central nuclei) arranged circumferentially around airway lumen",
                    connections: "Located in bronchiole walls between epithelium and connective tissue; regulated by autonomic nerves and circulating hormones (epinephrine dilates)",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: respHistologyCat.id,
                    name: "Adventitia",
                    aliases: ["Tunica adventitia (non-vessel)", "Outer connective tissue layer"],
                    function: "Outermost connective tissue layer anchoring the trachea and esophagus to surrounding structures; provides structural support and allows passage of vessels and nerves",
                    commonConfusions: ["Adventitia ≠ serosa: serosa = smooth slippery peritoneal covering for organs that move freely in body cavities; adventitia = connective tissue anchoring layer for organs that are FIXED to surrounding structures (like trachea/esophagus in the neck/thorax)", "Trachea and esophagus have adventitia (not serosa) because they are retroperitoneal/fixed — they don't float freely in a cavity"],
                    examTips: ["KEY DISTINCTION: on the trachea/esophagus slide, the outermost layer is ADVENTITIA (not serosa)", "Serosa = found on intraperitoneal organs (stomach, small intestine, most of colon); Adventitia = found on retroperitoneal/fixed organs (trachea, esophagus, kidneys, duodenum in part)", "Adventitia appears as loose connective tissue with no clear outer mesothelial boundary — just blending into surrounding tissue"],
                    histology: "Loose connective tissue (collagen fibers, fibroblasts, adipocytes, blood vessels, nerves) with no distinct mesothelial lining",
                    connections: "Outermost layer of trachea and esophagus; blends into surrounding mediastinal connective tissue and fascia",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Gastrointestinal Histology
        if let giHistologyCat = categories.first(where: { $0.name == "Gastrointestinal Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Esophagus",
                    aliases: ["Oesophagus"],
                    function: "Muscular tube propelling food via peristalsis; lined with stratified squamous epithelium for protection against abrasion from swallowed food boluses — one of the MOST important IDs in the entire GI tract",
                    commonConfusions: ["Esophagus is the ONLY GI organ lined by stratified squamous epithelium — all others (stomach, intestines) are simple columnar; this is the single most important diagnostic feature", "Trachea vs Esophagus on Slide #02: TRACHEA = cartilage rings + pseudostratified ciliated columnar epithelium; ESOPHAGUS = NO cartilage + stratified squamous epithelium — VERY important distinction", "Esophagus has submucosal mucous glands (like Brunner's in duodenum) — but context is always stratified squamous, never simple columnar"],
                    examTips: ["KEY ID: thick stratified squamous lining + NO villi + NO gastric pits + often collapsed/muscular tube appearance = ESOPHAGUS", "On the trachea/esophagus slide: find the cartilage → that side is trachea; the other tube with layered thick epithelium and no cartilage = esophagus", "Layers: mucosa (stratified squamous) → muscularis mucosae → submucosa (with mucous glands) → muscularis externa → adventitia (NOT serosa)"],
                    histology: "Mucosa: non-keratinized stratified squamous epithelium (multiple cell layers, protective); muscularis mucosae (longitudinal only); submucosa: loose CT with esophageal mucous glands; muscularis: upper = skeletal, middle = mixed, lower = smooth muscle; adventitia (fixed organ, no serosa)",
                    connections: "Pharynx → upper esophageal sphincter → esophagus → lower esophageal sphincter → stomach cardia",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Ileum",
                    aliases: ["Distal small intestine", "Terminal ileum"],
                    function: "Final segment of small intestine; absorbs vitamin B12, bile salts, and remaining nutrients; contains Peyer's patches for immune surveillance of intestinal contents",
                    commonConfusions: ["Ileum vs jejunum: ileum has Peyer's patches (large lymphoid aggregates visible in submucosa/mucosa); jejunum does NOT — Peyer's patches are the definitive marker of ileum", "Ileum vs duodenum: duodenum has Brunner's glands in submucosa; ileum does NOT", "Ileum has shorter villi and more goblet cells than jejunum — but Peyer's patches are the reliable exam ID feature"],
                    examTips: ["KEY ID: villi present + Peyer's patches (large purple lymphoid nodules) in submucosa/mucosa = ileum", "Peyer's patches appear as large dome-shaped masses of lymphoid tissue — they may distort the overlying mucosa and push into the lumen", "The FAE (follicle-associated epithelium) over Peyer's patches has fewer goblet cells and specialized M cells for antigen sampling"],
                    images: [ImageCDN.slide("ileum_histo_1.jpeg", magnification: 10, caption: "Ileum — Peyer's patch visible 10×")],
                    histology: "Mucosa: simple columnar epithelium with villi (shorter than jejunum) and goblet cells; crypts of Lieberkühn; muscularis mucosae; submucosa: contains Peyer's patches (aggregated lymphoid nodules); muscularis: inner circular + outer longitudinal; serosa",
                    connections: "Receives chyme from jejunum; terminates at ileocecal valve → large intestine; Peyer's patches sample luminal antigens via M cells; supplied by ileal branches of cranial mesenteric artery",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Jejunum",
                    aliases: ["Middle small intestine"],
                    function: "Primary site of nutrient absorption following digestion; absorbs amino acids, fatty acids, sugars, vitamins, and minerals; has the tallest villi and most active absorptive surface of the small intestine",
                    commonConfusions: ["Jejunum vs duodenum: duodenum has Brunner's glands in submucosa; jejunum does NOT — absence of Brunner's glands + presence of villi = jejunum or ileum", "Jejunum vs ileum: ileum has Peyer's patches (lymphoid aggregates in submucosa/mucosa); jejunum does NOT — absence of Peyer's patches distinguishes jejunum from ileum", "Jejunum has the tallest villi of the small intestine — longer villi than ileum on average"],
                    examTips: ["KEY ID LOGIC: villi present + NO Brunner's glands + NO Peyer's patches = jejunum", "Duodenum = Brunner's glands; Ileum = Peyer's patches; Jejunum = neither — use exclusion to ID it", "Goblet cells increase from duodenum → jejunum → ileum; jejunum has an intermediate number"],
                    images: [ImageCDN.slide("jejunum_histo_1.jpeg", magnification: 10, caption: "Jejunum — tall villi, no Brunner's, no Peyer's patches 10×")],
                    histology: "Mucosa: simple columnar epithelium with tall villi and goblet cells; crypts of Lieberkühn; muscularis mucosae; submucosa: loose CT, NO Brunner's glands, NO Peyer's patches; muscularis: inner circular + outer longitudinal smooth muscle; serosa",
                    connections: "Receives chyme from duodenum; transitions into ileum; suspended by mesentery; supplied by jejunal branches of cranial mesenteric artery",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Gall Bladder",
                    aliases: ["Gallbladder", "Cholecyst"],
                    function: "Stores and concentrates bile produced by the liver; releases bile into the duodenum via the common bile duct in response to cholecystokinin (CCK) when fat enters the small intestine",
                    commonConfusions: ["Gall bladder has NO muscularis mucosae — this is the key distinguishing histological feature (all other GI organs have it)", "Gall bladder has NO submucosa — another unique feature; the mucosa sits directly on the muscularis", "The highly folded mucosa resembles villi but these are mucosal FOLDS (rugae), not true villi — they flatten when the gallbladder is distended"],
                    examTips: ["KEY ID: highly folded simple columnar mucosa + NO muscularis mucosae + NO submucosa = gall bladder", "The epithelium is simple columnar with apical modifications for water absorption (concentrates bile 10×)", "Rokitansky-Aschoff sinuses: invaginations of epithelium into the muscularis — may be visible on slides and are a normal variant"],
                    histology: "Mucosa: simple columnar epithelium (tall, with apical microvilli) on lamina propria; NO muscularis mucosae; NO submucosa; muscularis: interlacing smooth muscle bundles (not distinct layers); perimuscular connective tissue; serosa (on free surface) or adventitia (hepatic surface)",
                    connections: "Receives bile from liver via cystic duct ← hepatic duct; releases bile via cystic duct → common bile duct → sphincter of Oddi → duodenum; sits in gallbladder fossa on visceral liver surface",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Cardiac Stomach",
                    aliases: ["Cardia", "Cardiac region of stomach"],
                    function: "Transitional zone at the esophagus-stomach junction; primarily mucus secretion to protect the cardia from acid reflux; the point where stratified squamous epithelium transitions to simple columnar",
                    commonConfusions: ["Cardiac stomach vs esophagus: esophagus = stratified squamous; cardiac stomach = simple columnar — the transition between them is abrupt and visible on slides", "Cardiac stomach vs fundic stomach: cardiac has more mucus glands, fewer acid-secreting structures, less intensely glandular appearance", "Cardiac glands are mucus-only — no parietal cells, no chief cells (those are in fundic glands)"],
                    examTips: ["KEY ID: simple columnar epithelium + gastric pits + cardiac glands (mucus-producing) + NO villi = cardiac stomach", "Compared with esophagus: epithelium switches from stratified squamous → simple columnar at the cardia", "Compared with fundic stomach: less densely glandular, more mucous appearance, shallower glands"],
                    histology: "Mucosa: simple columnar epithelium; gastric pits opening into cardiac glands (coiled, mucus-secreting tubular glands); lamina propria; muscularis mucosae; submucosa; muscularis; serosa",
                    connections: "Junction of esophagus and stomach; cardiac sphincter (lower esophageal sphincter) just above; transitions into fundic region",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Gastric Pits",
                    aliases: ["Foveolae gastricae"],
                    function: "Invaginations of the gastric surface epithelium into the mucosa; each pit leads into one or more gastric glands; present in all regions of the stomach",
                    commonConfusions: ["Gastric pits are different from glands — the pit is the opening/channel; the gland is the secretory unit at the bottom", "Pyloric pits are deeper than fundic pits — pits:gland ratio differs by region"],
                    examTips: ["KEY ID for ANY stomach region: gastric pits (invaginations) + simple columnar epithelium + NO villi = stomach", "Depth of pits varies: cardiac/fundic = shallow pits; pyloric = deeper pits", "Gastric pits line the entire stomach surface — seeing them confirms you are in stomach, not intestine"],
                    histology: "Simple columnar epithelium lining; surface mucous cells (tall columnar with apical mucin granules) line the pit walls; gland openings at the pit base",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Cardiac Glands",
                    aliases: ["Cardia glands"],
                    function: "Mucus-secreting glands of the cardiac stomach; protect the cardia from acid and mechanical damage",
                    examTips: ["Mucus-only glands — distinguish from fundic glands which have parietal + chief cells", "Located near the esophagogastric junction"],
                    histology: "Coiled, branched tubular mucous glands; pale-staining cells with basal nuclei and apical mucin"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Fundic Stomach",
                    aliases: ["Fundus of stomach", "Body of stomach", "Fundic region"],
                    function: "Major site of gastric digestion; produces HCl (parietal cells), pepsinogen (chief cells), and intrinsic factor (parietal cells); the most extensively glandular region of the stomach",
                    commonConfusions: ["Fundic stomach vs cardiac stomach: fundic is MUCH more glandular, deeper glands, visible parietal cells (large pink cells) and chief cells (basophilic)", "Fundic stomach vs pyloric stomach: fundic has deeper glands extending almost full mucosal thickness; pyloric glands are more coiled/tortuous and more mucus-heavy", "Parietal cells are ONLY in fundic (and some cardiac) glands — NOT in pyloric glands"],
                    examTips: ["KEY ID: thick, dense glandular mucosa + gastric pits + fundic glands + parietal cells (large eosinophilic/pink) + chief cells (basophilic) = fundic stomach", "Compared with cardiac: much more intensely glandular, deeper glands", "Compared with pyloric: fundic glands are straighter; pyloric glands are coiled and more mucus-heavy with deeper pits"],
                    histology: "Mucosa: simple columnar surface epithelium; gastric pits (shallow); fundic glands occupying most of mucosal thickness — contain: mucous neck cells (top), parietal cells (middle, large pink oxyphilic), chief cells (bottom, basophilic, zymogen granules); muscularis mucosae; submucosa; muscularis (3 layers in stomach); serosa",
                    connections: "Main body of stomach; receives food from cardiac region; transitions to pyloric antrum; glands drain via gastric pits to lumen",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Fundic Glands",
                    aliases: ["Gastric glands", "Fundus glands"],
                    function: "Main secretory glands of the stomach; produce HCl (parietal cells), pepsinogen (chief cells), intrinsic factor (parietal cells), and mucus (mucous neck cells)",
                    commonConfusions: ["Parietal cells (HCl + intrinsic factor) vs chief cells (pepsinogen) — both are in fundic glands but at different depths: parietal = mid-gland, chief = base of gland", "Fundic glands vs cardiac/pyloric glands: fundic glands are the only ones with parietal AND chief cells"],
                    examTips: ["PARIETAL CELLS: large, triangular/pyramidal, intensely eosinophilic (bright pink) — the most recognizable cell in stomach histology", "CHIEF CELLS: smaller, basophilic (purple-blue), at base of gland — pepsinogen-secreting", "Gland zones from pit to base: isthmus (stem cells) → neck (mucous neck cells) → base (chief cells); parietal cells throughout mid-gland"],
                    histology: "Parietal cells: large, eosinophilic, with intracellular canaliculi; chief cells: basophilic, pyramidal, zymogen granules; mucous neck cells: pale, mucin-filled",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Pyloric Stomach",
                    aliases: ["Pyloric antrum", "Pyloric region", "Pylorus"],
                    function: "Regulates gastric emptying into duodenum; secretes mucus and gastrin; the pyloric sphincter controls chyme release; more mucus-dominated than fundic region",
                    commonConfusions: ["Pyloric stomach vs fundic stomach: pyloric has deeper pits (pit:gland ratio higher), more coiled/tortuous glands, more mucus-heavy, fewer acid-secreting cells", "Pyloric stomach vs intestine: pyloric still has NO villi — this is critical; only intestine has villi", "G cells in pyloric glands produce gastrin — these are enteroendocrine cells, not the same as surface mucous cells"],
                    examTips: ["KEY ID: simple columnar + deep gastric pits + coiled mucus-heavy pyloric glands + G cells + NO villi = pyloric stomach", "Compared with fundic: pits are deeper relative to gland length; glands appear more coiled/tortuous and paler (more mucus)", "Compared with intestine: no villi in pyloric stomach — the surface is still folded rugae, not finger-like villi"],
                    images: [ImageCDN.slide("pyloric-stomach_histo_1.jpeg", magnification: 10, caption: "Pyloric Stomach — deep pits, coiled glands 10×")],
                    histology: "Mucosa: simple columnar epithelium; deep gastric pits (occupy ~half the mucosal thickness); pyloric glands (coiled, branched tubular glands, primarily mucus-secreting with G cells interspersed); muscularis mucosae; submucosa; muscularis (including thick pyloric sphincter); serosa",
                    connections: "Distal stomach; receives partially digested chyme from fundic region; pyloric sphincter → duodenum; gastrin from G cells enters bloodstream → stimulates parietal cells",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Pyloric Glands",
                    aliases: ["Antral glands"],
                    function: "Mucus-secreting glands of the pyloric stomach; also contain G cells which produce gastrin to stimulate acid secretion",
                    examTips: ["Pyloric glands are coiled and mucus-heavy — more tortuous than fundic glands", "Deep gastric pits with relatively shorter glands compared to fundic region"],
                    images: [ImageCDN.slide("pyloric-stomach_histo_1.jpeg", magnification: 10, caption: "Pyloric Glands — 10×")],
                    histology: "Branched, coiled tubular glands; pale mucous cells with basally located nuclei; G cells scattered among mucous cells (enteroendocrine, not visible without special stains)"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "G Cells",
                    aliases: ["Gastrin-producing cells", "Enteroendocrine G cells"],
                    function: "Produce and secrete gastrin in response to food, stomach distension, and vagal stimulation; gastrin travels via bloodstream to stimulate parietal cells to produce HCl",
                    commonConfusions: ["G cells are in the PYLORIC region — not fundic or cardiac", "G cells are enteroendocrine cells scattered among mucous cells — not visible as a distinct population without special staining"],
                    examTips: ["G cells are in pyloric glands — their presence defines the pyloric region functionally", "Gastrin → stimulates parietal cells → HCl production — classic feedback loop"],
                    histology: "Enteroendocrine cells; triangular with basally located secretory granules; located among pyloric gland cells; not easily distinguished on H&E without immunohistochemistry"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Duodenum",
                    aliases: ["First part of small intestine", "C-loop"],
                    function: "First and shortest segment of the small intestine; primary site of chemical digestion (receives pancreatic enzymes and bile); neutralizes acidic chyme; begins nutrient absorption",
                    commonConfusions: ["Duodenum vs jejunum: BRUNNER'S GLANDS in submucosa = duodenum — this is the single best way to identify it; jejunum has NO Brunner's glands", "Duodenum vs stomach: duodenum has VILLI (stomach does not) — once you see villi, you are in small intestine", "Duodenum vs ileum: ileum has Peyer's patches; duodenum has Brunner's glands — never both"],
                    examTips: ["KEY ID: villi + simple columnar epithelium + BRUNNER'S GLANDS in submucosa = duodenum (VERY important slide)", "Brunner's glands are SUBMUCOSAL — they sit below the muscularis mucosae; crypts of Lieberkühn are mucosal", "Look for the pale-staining glandular tissue BELOW the muscularis mucosae band — that's Brunner's glands"],
                    histology: "Mucosa: simple columnar epithelium with villi (shorter than jejunum), goblet cells, crypts of Lieberkühn; muscularis mucosae; submucosa: Brunner's glands (key ID feature); muscularis: inner circular + outer longitudinal; adventitia (partially retroperitoneal)",
                    connections: "Pyloric sphincter → duodenum → jejunum; receives common bile duct and pancreatic duct at ampulla of Vater/hepatopancreatic ampulla; C-shaped loop around head of pancreas",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Villi",
                    aliases: ["Intestinal projections"],
                    function: "Increase absorption surface area",
                    examTips: ["Cover intestinal lumen"],
                    images: [ImageCDN.slide("ileum_histo_1.jpeg", magnification: 10, caption: "Villi — Ileum 10×")],
                    histology: "Simple columnar epithelium with microvilli"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Goblet Cells",
                    aliases: ["Mucus-secreting cells"],
                    function: "Produces protective mucus layer",
                    examTips: ["Increases up colon"],
                    images: [ImageCDN.slide("ileum_histo_1.jpeg", magnification: 10, caption: "Goblet Cells — Ileum 10×")],
                    histology: "Goblet-shaped; PAS-positive"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Crypts of Lieberkühn",
                    aliases: ["Intestinal crypts"],
                    function: "Produces replacement epithelial cells",
                    examTips: ["Continuous cell renewal"],
                    images: [ImageCDN.slide("ileum_histo_1.jpeg", magnification: 10, caption: "Crypts of Lieberkühn — Ileum 10×")],
                    histology: "Simple columnar epithelium"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Peyer's Patches",
                    aliases: ["Gut-associated lymphoid tissue"],
                    function: "Immune surveillance",
                    examTips: ["Found in small intestine"],
                    images: [ImageCDN.slide("ileum_histo_1.jpeg", magnification: 10, caption: "Peyer's Patches — Ileum 10×")],
                    histology: "Lymphoid tissue in lamina propria"
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Brunner's Glands",
                    aliases: ["Duodenal glands", "Glands of Brunner"],
                    function: "Produces alkaline, mucus-rich secretion that neutralizes acidic chyme from the stomach, protects the duodenal mucosa, and provides an optimal pH for pancreatic enzyme activity",
                    commonConfusions: ["Brunner's glands are found ONLY in the duodenum — their presence in the SUBMUCOSA is the definitive histological marker that distinguishes duodenum from jejunum and ileum", "Most intestinal glands (crypts of Lieberkühn) are in the mucosa; Brunner's glands are SUBMUCOSAL"],
                    examTips: ["KEY ID: Brunner's glands in the submucosa = duodenum (not jejunum or ileum)", "On the duodenum slide, look for glands that dip down into the submucosa layer beneath the muscularis mucosae — those are Brunner's glands", "Both duodenum AND esophagus have submucosal glands — but esophageal glands are in stratified squamous epithelium context, duodenum is simple columnar"],
                    histology: "Compound tubular mucous glands located in the submucosa; cells are pale-staining (mucin-rich), cuboidal to columnar",
                    connections: "Located in submucosa of duodenum only; their secretory ducts open up through muscularis mucosae into base of crypts; activated by gastric acid and secretin",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Muscularis Mucosae",
                    aliases: ["Muscular mucosae", "Inner smooth muscle layer of mucosa"],
                    function: "Thin smooth muscle layer at the base of the mucosa; causes local folding and movement of the mucosal layer — helps empty glands, rearrange villi, and enhance local mixing without full-layer peristalsis",
                    commonConfusions: ["Muscularis mucosae (thin, inner, in mucosa) vs muscularis (thick outer muscle layers that drive peristalsis) — they are different layers", "The muscularis mucosae is part of the MUCOSA; the muscularis is a separate, much larger outer layer"],
                    examTips: ["Layer order from lumen outward: mucosa (epithelium + lamina propria + muscularis mucosae) → submucosa → muscularis → serosa/adventitia", "Practical ID: thin pink smooth muscle band just deep to the mucosa; separates mucosa from submucosa", "The muscularis mucosae is the boundary between mucosa and submucosa — use it as your landmark for layer identification"],
                    histology: "Thin layer of smooth muscle (1-2 cell layers); inner circular and sometimes outer longitudinal orientation; cells are smooth, elongated, non-striated",
                    connections: "Base of the mucosa; deep to the lamina propria; superficial to the submucosa; present throughout the GI tract from esophagus to rectum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Submucosa",
                    aliases: ["Submucosal layer"],
                    function: "Connective tissue layer beneath the mucosa; supports blood vessels, lymphatics, and nerves (Meissner's plexus) traveling to the mucosa; in duodenum also contains Brunner's glands",
                    commonConfusions: ["Submucosa is between muscularis mucosae and muscularis — it's a connective tissue layer, not muscle", "Special features by region: duodenum (Brunner's glands in submucosa), esophagus (mucous glands in submucosa), ileum (Peyer's patches extend into submucosa)"],
                    examTips: ["Layer order: mucosa → submucosa → muscularis → serosa", "Practical ID: pale-staining loose connective tissue layer between the muscularis mucosae and the thick muscularis; contains visible blood vessels", "Submucosa = the 'support layer' — look for vessels and connective tissue, no epithelial cells, no large muscle bundles"],
                    histology: "Loose areolar connective tissue; contains blood vessels (arteries, veins, capillaries), lymphatic vessels, Meissner's submucosal nerve plexus, and in specific regions glands (Brunner's, esophageal)",
                    connections: "Deep to muscularis mucosae; superficial to muscularis; present throughout GI tract; carries submucosal blood supply and Meissner's plexus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Muscularis",
                    aliases: ["Muscularis externa", "Smooth muscle layers of GI wall", "Inner circular / outer longitudinal muscle"],
                    function: "The main muscle coat of the GI wall responsible for peristalsis (wave-like propulsion of contents) and mixing/churning movements; contains the Auerbach's (myenteric) nerve plexus between its layers",
                    commonConfusions: ["Muscularis has TWO layers: inner circular (constricts lumen) + outer longitudinal (shortens segment) — both needed for peristalsis", "Muscularis ≠ muscularis mucosae; muscularis is OUTER and much thicker; muscularis mucosae is thin and inner"],
                    examTips: ["Practical ID: thick double smooth muscle layer outside the submucosa — the largest-looking muscle region on any GI slide", "Inner circular layer = muscle cells cut in CROSS section (round profiles); outer longitudinal layer = muscle cells cut in LONGITUDINAL section (elongated profiles)", "The stomach has an additional third layer (oblique) making three layers total — this is why the stomach wall looks extra thick"],
                    histology: "Two layers of smooth muscle: inner circular (perpendicular to gut axis) and outer longitudinal (parallel to gut axis); Auerbach's myenteric plexus sits between the two layers",
                    connections: "Deep to submucosa; superficial to serosa/adventitia; extends throughout GI tract from esophagus to rectum; Auerbach's plexus coordinates peristaltic waves",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Serosa",
                    aliases: ["Visceral peritoneum", "Serosal layer", "Outer serosal coat"],
                    function: "Outermost layer of intraperitoneal GI organs; smooth, slippery surface that reduces friction as organs slide against each other during digestion and movement; continuous with the peritoneum lining the body cavity",
                    commonConfusions: ["Serosa ≠ adventitia: serosa = slippery peritoneal covering for intraperitoneal organs; adventitia = anchoring connective tissue for retroperitoneal/fixed organs", "NOT all digestive organs have serosa: the esophagus and duodenum (retroperitoneal portions) have adventitia instead", "The handout notes 'serosa may not be present on your slide' for ileum and large intestine — the serosa is the outermost thin layer and may be lost during slide preparation"],
                    examTips: ["Practical ID: outermost thin layer on GI slides — a wispy layer of connective tissue + simple squamous mesothelium on the outside surface", "May be absent from slides or cut off during sectioning — if the outermost visible layer looks like muscle, the serosa was trimmed", "Organs WITH serosa: stomach, most of small intestine (except duodenum), much of colon; WITHOUT serosa (have adventitia instead): esophagus, duodenum, rectum"],
                    histology: "Simple squamous mesothelium (one cell layer) over a thin layer of loose connective tissue (sub-mesothelial connective tissue)",
                    connections: "Outermost GI wall layer for intraperitoneal organs; continuous with visceral peritoneum; parietal peritoneum on opposite side lines body wall; fluid between them reduces friction",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Large Intestine",
                    aliases: ["Colon histology", "Large bowel", "Intestinum crassum"],
                    function: "Absorbs water and electrolytes from indigestible food residue; consolidates waste into feces; no enzymatic digestion or nutrient absorption of note (contrast with small intestine)",
                    commonConfusions: ["Large intestine has NO villi — this is the key diagnostic feature distinguishing it from small intestine on a histology slide", "Large intestine has many more goblet cells than small intestine — the increased goblet cells produce mucus to lubricate fecal passage", "Large intestine vs small intestine on slides: small intestine = villi + fewer goblet cells; large intestine = no villi + many goblet cells"],
                    examTips: ["KEY HISTOLOGICAL DIAGNOSIS: NO villi + abundant goblet cells = large intestine", "The mucosa is flat (no villi) but still has crypts of Lieberkühn (intestinal glands) opening at the flat surface", "Practical study: memorize the absence of villi as THE definitive marker — if you see villi, it's small intestine; if the surface is flat with many goblet cells, it's large intestine"],
                    images: [ImageCDN.slide("large-intestine_histo_1.jpeg", magnification: 10, caption: "Large Intestine — no villi, abundant goblet cells 10×")],
                    histology: "Mucosa: simple columnar epithelium with abundant goblet cells, flat surface (NO villi), crypts of Lieberkühn; muscularis mucosae; submucosa; muscularis (inner circular + outer longitudinal); serosa (if intraperitoneal) or adventitia",
                    connections: "Receives unabsorbed material from ileum via ileocecal valve; segments: cecum → ascending → transverse → descending → sigmoid colon → rectum → anus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Caecum",
                    aliases: ["Cecum", "Cecal pouch"],
                    function: "Blind-ended pouch at the start of the large intestine; site of microbial fermentation (especially in herbivores); absorbs water and electrolytes; transitional morphology between ileum and colon",
                    commonConfusions: ["Caecum vs ileum: caecum has reduced or absent villi + more goblet cells; ileum has villi + Peyer's patches", "Caecum vs colon: both lack villi and have abundant goblet cells; caecum is a blind pouch grossly — histologically transitional appearance", "In pigs the caecum is large and important for fermentation — more prominent than in humans"],
                    examTips: ["KEY ID: more goblet cells + fewer/reduced villi + transitional morphology toward large intestine = caecum", "May appear similar to proximal colon histologically — context (gross anatomy) helps differentiate", "The ileocecal valve is at the junction of ileum and caecum — villi disappear at this boundary"],
                    histology: "Mucosa: simple columnar epithelium with increasing goblet cells; villi reduced or absent; crypts of Lieberkühn present; muscularis mucosae; submucosa; muscularis; serosa",
                    connections: "Ileocecal valve → caecum → ascending colon; appendix (vermiform appendix) opens at caecum base",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Spiral Colon",
                    aliases: ["Spiral loop of colon", "Ansa spiralis"],
                    function: "Segment of colon unique to pigs arranged in a spiral/coiled pattern; absorbs water and electrolytes from digestive waste; consolidates feces; highly mucus-lubricated for fecal transit",
                    commonConfusions: ["Spiral colon vs small intestine: NO villi + abundant goblet cells = large intestine/spiral colon; small intestine has villi", "Spiral colon vs stomach: crypts (not gastric pits) + columnar epithelium + many goblet cells = colon; stomach has gastric pits and no goblet cells"],
                    examTips: ["KEY ID: abundant goblet cells + NO villi + flat mucosal surface + crypts of Lieberkühn = large intestine / spiral colon", "The spiral arrangement is a gross anatomical feature — histologically it looks like other large intestine segments", "Smooth luminal surface (no villi) + very many goblet cells = colon histology"],
                    images: [ImageCDN.slide("large-intestine_histo_1.jpeg", magnification: 10, caption: "Spiral Colon — no villi, abundant goblet cells 10×")],
                    histology: "Mucosa: simple columnar epithelium with extremely abundant goblet cells; NO villi; crypts of Lieberkühn (deep, straight); flat mucosal surface; muscularis mucosae; submucosa; muscularis: inner circular + outer longitudinal (taenia coli in humans; fused in pigs); serosa",
                    connections: "Continuation of ascending/transverse colon in pigs; coiled spiral arrangement; transitions to descending colon then rectum",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: giHistologyCat.id,
                    name: "Rectum",
                    aliases: ["Rectal ampulla", "Terminal large intestine"],
                    function: "Stores feces prior to defecation; highly lubricated by goblet cell mucus; the distal transition toward stratified squamous epithelium at the anal canal is a unique histological feature",
                    commonConfusions: ["Proximal rectum vs colon: histologically similar — both have goblet cells, no villi, crypts; rectum is more mucus-heavy and approaches stratified squamous distally", "Distal rectum vs esophagus: both transition to stratified squamous — but context is completely different (rectum is distal GI, esophagus is proximal)", "Rectum has adventitia (retroperitoneal below peritoneal reflection) rather than serosa — similar to esophagus and duodenum"],
                    examTips: ["KEY ID of distal rectum: approaching stratified squamous transition + goblet-cell-rich mucosa + large intestine architecture", "Proximal rectum is histologically indistinguishable from colon without gross context", "Rectum has adventitia (not serosa) — the peritoneum does not cover the lower rectum"],
                    histology: "Proximal: simple columnar epithelium with abundant goblet cells, no villi, crypts; approaching anus: abrupt transition to non-keratinized stratified squamous (anorectal junction); muscularis: inner circular (forms internal anal sphincter distally) + outer longitudinal; adventitia in lower rectum",
                    connections: "Sigmoid colon → rectum → anal canal → anus; internal anal sphincter (smooth muscle) + external anal sphincter (skeletal muscle) control defecation",
                    highYield: false
                ),
            ])
        }

        // MARK: Liver Histology
        if let liverHistoCat = categories.first(where: { $0.name == "Liver Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: liverHistoCat.id,
                    name: "Liver Lobule",
                    aliases: ["Hepatic lobule"],
                    function: "Functional unit of liver",
                    examTips: ["Portal triads at corners"],
                    images: [ImageCDN.slide("liver_histo_1.jpeg", magnification: 10, caption: "Liver Lobule — 10×")],
                    histology: "Hexagonal arrangement of hepatocytes"
                ),
                AnatomyStructure(
                    categoryId: liverHistoCat.id,
                    name: "Portal Triad",
                    aliases: ["Portal tract", "Portal area"],
                    function: "The portal triad is the vascular + ductal unit at the PERIPHERY of each liver lobule; it supplies blood into the lobule and drains bile out; contains three structures: branch of portal vein (nutrient-rich), branch of hepatic artery (oxygenated), and a bile duct (carries bile away from hepatocytes)",
                    commonConfusions: ["Portal triad = PERIPHERY of lobule; central vein = CENTER of lobule — this directionality is the most important liver histology concept", "Three structures in the portal triad: portal vein branch, hepatic artery branch, bile duct — students often forget the bile duct or confuse flow direction (blood flows FROM triad TOWARD central vein; bile flows OPPOSITE, from hepatocytes TOWARD triad)"],
                    examTips: ["CRITICAL DISTINCTION: Portal triad (periphery) → blood flows inward through sinusoids → central vein (center)", "On the liver slide: look for clusters of 3 structures at lobule corners = portal triad; the single large thin-walled vessel in the middle = central vein", "Bile flow is OPPOSITE to blood flow: bile canaliculi → bile ductules → portal triad bile duct → hepatic duct → common bile duct → duodenum"],
                    images: [ImageCDN.slide("liver_histo_1.jpeg", magnification: 10, caption: "Portal Triad — 10×")],
                    histology: "Portal vein branch: large, thin-walled, irregular; hepatic artery branch: smaller, thick-walled, round; bile duct: lined by simple cuboidal/columnar epithelium; all embedded in connective tissue stroma",
                    connections: "Portal vein branch receives nutrient-rich blood from GI tract; hepatic artery branch receives oxygenated blood from celiac artery; bile duct drains toward hepatic ducts; located at periphery of liver lobule",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: liverHistoCat.id,
                    name: "Central Vein",
                    aliases: ["Central vein of liver lobule", "Terminal hepatic venule"],
                    function: "Collects blood after it has passed through the liver sinusoids and been processed by hepatocytes; drains into sublobular veins → hepatic veins → caudal vena cava; the central vein is the endpoint of blood flow within one liver lobule",
                    commonConfusions: ["VERY IMPORTANT: portal triad = periphery of lobule; central vein = CENTER of lobule — these are opposite ends of the blood flow direction through the lobule", "Central vein is NOT the portal vein — the portal vein enters at the triad (periphery); the central vein drains blood out at the center after hepatocyte processing"],
                    examTips: ["MOST IMPORTANT liver histology landmark: find the large thin-walled open vessel in the CENTER of the lobule = central vein; find the cluster of 3 vessels/duct at the PERIPHERY = portal triad", "Blood flow direction: portal triad (in) → sinusoids → hepatocytes → central vein (out) → hepatic vein → caudal vena cava", "On the slide: central vein appears as a single large, thin-walled, round/oval vessel with an open lumen at the center of the lobule"],
                    images: [ImageCDN.slide("liver_histo_1.jpeg", magnification: 10, caption: "Central Vein — 10×")],
                    histology: "Simple squamous endothelium lining (like all veins); very thin wall with minimal smooth muscle (low pressure); the lumen is often wide and irregular; surrounded by hepatocyte plates converging toward it",
                    connections: "Receives: blood from liver sinusoids (after hepatocyte processing); drains into: sublobular veins → hepatic veins → caudal vena cava; located at the CENTER of each liver lobule",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: liverHistoCat.id,
                    name: "Hepatocyte",
                    aliases: ["Liver cell"],
                    function: "Performs liver functions",
                    examTips: ["Primary liver cell type"],
                    images: [ImageCDN.slide("liver_histo_1.jpeg", magnification: 10, caption: "Hepatocytes — 10×")],
                    histology: "Large cuboidal cells with multiple nuclei"
                ),
            ])
        }

        // MARK: Pancreas Histology
        if let pancreasHistoCat = categories.first(where: { $0.name == "Pancreas Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: pancreasHistoCat.id,
                    name: "Acinus",
                    aliases: ["Pancreatic acinus"],
                    function: "Secretes digestive enzymes",
                    examTips: ["Functional unit of exocrine pancreas"],
                    histology: "Cluster of secretory acinar cells surrounding a small lumen"
                ),
                AnatomyStructure(
                    categoryId: pancreasHistoCat.id,
                    name: "Acinar Cells",
                    aliases: ["Pancreatic acinar cells"],
                    function: "Produces digestive secretions",
                    examTips: ["Zymogen granules for enzyme storage"],
                    histology: "Cuboidal cells with basophilic cytoplasm and apical zymogen granules"
                ),
                AnatomyStructure(
                    categoryId: pancreasHistoCat.id,
                    name: "Islet of Langerhans",
                    aliases: ["Pancreatic islet", "Islets of Langerhans"],
                    function: "Endocrine component of the pancreas — produces insulin (beta cells, lowers blood glucose), glucagon (alpha cells, raises blood glucose), and somatostatin (delta cells, regulates both); releases hormones directly into bloodstream with no duct",
                    commonConfusions: ["Islets (endocrine, no duct, into blood) vs acini (exocrine, has ducts, into duodenum) — this acini vs. islets distinction is one of the most tested pancreas histology concepts", "On the slide: islets appear as lighter-staining rounded 'islands' surrounded by the darker acinar tissue"],
                    examTips: ["KEY ID: islets appear as pale, lightly stained rounded islands within the darker exocrine acinar tissue — the contrast makes them easy to spot", "Two functional compartments on one slide: exocrine (acini + ducts) and endocrine (islets) — the pancreas is both!"],
                    histology: "Clusters of pale polygonal endocrine cells without secretory granules visible by light microscopy; fenestrated capillaries throughout; beta cells most abundant (60%), alpha cells (25%), delta cells (10%)",
                    connections: "Scattered throughout pancreatic parenchyma; secrete insulin and glucagon into pancreatic capillaries → portal vein → liver (first-pass effect on glucose regulation)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: pancreasHistoCat.id,
                    name: "Interlobular / Intralobular Duct",
                    aliases: ["Pancreatic duct", "Intralobular duct", "Interlobular duct", "Pancreatic ductal system"],
                    function: "Carry digestive enzyme-rich secretions from pancreatic acini toward the main pancreatic duct and ultimately into the duodenum; intralobular ducts (small, within lobules) drain into interlobular ducts (larger, between lobules) → main pancreatic duct → duodenum",
                    commonConfusions: ["Pancreatic ducts (exocrine transport) vs blood vessels in the islets (endocrine release) — two entirely different delivery systems on the same slide", "Intralobular = small, within the lobule, lined by simple cuboidal; interlobular = larger, between lobules, lined by simple columnar with some connective tissue sheath"],
                    examTips: ["Practical ID on pancreas slide: look for small tubular structures with cuboidal lining among the acini — these are ducts; they are SMALLER and paler than acini", "Three things to identify on the pancreas slide: acini (exocrine secretory clusters), islets of Langerhans (pale endocrine islands), and ducts (tubular structures transporting secretions)", "Centroacinar cells = ductal cells that extend into the acinus — a unique pancreatic feature; they appear as pale cells in the center of an acinus"],
                    histology: "Intralobular ducts: simple cuboidal epithelium, small lumen, no connective tissue sheath; interlobular ducts: simple columnar to pseudostratified epithelium, larger lumen, surrounded by connective tissue stroma; centroacinar cells at acinus-duct junction",
                    connections: "Acinar cells → centroacinar cells → intralobular ducts → interlobular ducts → main pancreatic duct → joins common bile duct at hepatopancreatic ampulla (ampulla of Vater) → duodenum",
                    highYield: true
                ),
            ])
        }
        
        // MARK: Kidney Histology
        if let kidneyHistologyCat = categories.first(where: { $0.name == "Kidney Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Glomerulus",
                    aliases: ["Capillary network"],
                    function: "Filters blood to produce filtrate",
                    examTips: ["Site of ultrafiltration"],
                    histology: "Network of capillaries in Bowman's capsule"
                ),
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Bowman's Capsule",
                    aliases: ["Glomerular capsule"],
                    function: "Receives glomerular filtrate",
                    examTips: ["Forms start of nephron"],
                    histology: "Double-walled epithelium surrounding glomerulus"
                ),
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Proximal Convoluted Tubule",
                    aliases: ["PCT"],
                    function: "Reabsorbs useful substances",
                    examTips: ["First part of renal tubule"],
                    histology: "Simple cuboidal epithelium with microvilli"
                ),
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Distal Convoluted Tubule",
                    aliases: ["DCT"],
                    function: "Fine-tunes reabsorption and secretion",
                    examTips: ["Regulated by hormones"],
                    histology: "Simple cuboidal epithelium; shorter than PCT"
                ),
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Renal Cortex",
                    aliases: ["Outer kidney", "Cortex renalis"],
                    function: "Outer region of the kidney containing all glomeruli, Bowman's capsules, proximal convoluted tubules, and distal convoluted tubules; site of filtration and most tubular reabsorption",
                    commonConfusions: ["Renal cortex vs medulla on slides: cortex has glomeruli (round dark clusters) and lots of tubule cross-sections; medulla has NO glomeruli — only parallel tubules and collecting ducts", "The cortex appears more cellular/dense on low-power because it contains the packed nephron components (glomeruli + tubules)"],
                    examTips: ["KEY ID: if you see glomeruli = you are in the cortex; if no glomeruli = medulla", "On low power: cortex is the outer, darker-staining zone with visible round glomerular tufts; medulla is the inner zone with striped parallel tubules", "Renal columns (columns of Bertin) = cortical tissue that dips between medullary pyramids — still cortex histologically even though it's deeper"],
                    histology: "Glomeruli (capillary tufts) within Bowman's capsules; proximal convoluted tubules (simple cuboidal with prominent brush border microvilli); distal convoluted tubules (simple cuboidal, no brush border, smaller lumen); peritubular capillaries; interstitial connective tissue",
                    connections: "Outer region of kidney; receives blood from afferent arterioles → glomeruli → efferent arterioles → peritubular capillaries; filtrate flows: glomerulus → Bowman's capsule → PCT → loop of Henle (into medulla) → DCT → collecting duct",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: kidneyHistologyCat.id,
                    name: "Renal Medulla",
                    aliases: ["Inner kidney"],
                    function: "Contains loops of Henle and collecting ducts",
                    examTips: ["Sites of concentration and dilution"],
                    histology: "Pyramidal arrangement"
                ),
            ])
        }
        
        // MARK: Reproductive Histology
        if let reproHistologyCat = categories.first(where: { $0.name == "Reproductive Histology" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Primary Oocyte",
                    aliases: ["Arrested meiosis I"],
                    function: "Immature egg in prophase I",
                    examTips: ["Remains arrested until ovulation"],
                    histology: "Large cell with large nucleus"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Primary Follicle",
                    aliases: ["Primordial follicle"],
                    function: "Early stage oocyte with surrounding cells",
                    examTips: ["Surrounds primary oocyte"],
                    histology: "Single layer of follicle cells"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Secondary Follicle",
                    aliases: ["Growing follicle"],
                    function: "Developing oocyte with multiple cell layers",
                    examTips: ["Begins estrogen production"],
                    histology: "Multiple layers of granulosa cells"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Tertiary Follicle",
                    aliases: ["Mature Graafian follicle"],
                    function: "Ready for ovulation",
                    examTips: ["Largest ovarian follicle"],
                    histology: "Large with antrum containing fluid"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Antrum",
                    aliases: ["Follicular cavity"],
                    function: "Fluid-filled space in tertiary follicle",
                    examTips: ["Expands as follicle matures"],
                    histology: "Contains follicular fluid"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Corpus Luteum",
                    aliases: ["Yellow body"],
                    function: "Produces progesterone after ovulation",
                    examTips: ["Temporary endocrine gland"],
                    histology: "Lutein cells from granulosa cells"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Seminiferous Tubule",
                    aliases: ["Sperm-producing tubule"],
                    function: "Site of spermatogenesis",
                    examTips: ["Packed with developing sperm"],
                    histology: "Pseudostratified columnar with spermatogenic cells"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Spermatogonia",
                    aliases: ["Sperm stem cells"],
                    function: "Continuously produce primary spermatocytes",
                    examTips: ["At outer edge of tubule"],
                    histology: "Diploid stem cells"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Spermatocytes",
                    aliases: ["Dividing sperm cells"],
                    function: "Divide to produce spermatids",
                    examTips: ["Undergo meiosis"],
                    histology: "Primary (diploid) and secondary (haploid)"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Spermatids",
                    aliases: ["Young sperm"],
                    function: "Differentiate into spermatozoa",
                    examTips: ["Final stage before mature sperm"],
                    histology: "Haploid cells undergoing spermiogenesis"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Spermatozoa",
                    aliases: ["Mature sperm"],
                    function: "Male gamete",
                    examTips: ["Released into lumen"],
                    histology: "Head, midpiece, tail; very motile"
                ),
                AnatomyStructure(
                    categoryId: reproHistologyCat.id,
                    name: "Leydig Cells",
                    aliases: ["Interstitial cells"],
                    function: "Produces testosterone",
                    examTips: ["Endocrine cells of testis"],
                    histology: "Located between seminiferous tubules"
                ),
            ])
        }
        
        // MARK: Microscope
        if let microscopeCat = categories.first(where: { $0.name == "Microscope" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Light Source/Illuminator",
                    aliases: ["Lamp", "Illumination"],
                    function: "Provides light for specimen viewing"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Coarse Focus Knob",
                    aliases: ["Large focus dial"],
                    function: "Makes large adjustments to focus"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Fine Focus Knob",
                    aliases: ["Small focus dial"],
                    function: "Makes fine adjustments to focus"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Objective Lenses",
                    aliases: ["Turret lenses"],
                    function: "Primary magnification of specimen"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Ocular Lens",
                    aliases: ["Eyepiece"],
                    function: "Secondary magnification; viewed by eye",
                    images: [
                        ImageCDN.image("ocular-lens_gross_1.jpeg"),
                    ]
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Arm",
                    aliases: ["Microscope body"],
                    function: "Supports objective lenses and stage"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Base",
                    aliases: ["Foot"],
                    function: "Provides stability and support"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Stage",
                    aliases: ["Specimen platform"],
                    function: "Holds specimen slide"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Slide Holder",
                    aliases: ["Slide clip"],
                    function: "Secures slide on stage"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Aperture/Iris Diaphragm",
                    aliases: ["Diaphragm"],
                    function: "Controls amount of light passing through"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Revolving Nosepiece",
                    aliases: ["Turret"],
                    function: "Rotates objective lenses for selection"
                ),
                AnatomyStructure(
                    categoryId: microscopeCat.id,
                    name: "Condenser",
                    aliases: ["Illumination system"],
                    function: "Focuses light onto specimen",
                    images: [ImageCDN.image("condenser_gross_1.jpeg", caption: "Condenser")]
                ),
            ])
        }
        
        
        // MARK: Peritoneal Cavity
        if let peritonealCat = categories.first(where: { $0.name == "Peritoneal Cavity" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Peritoneal Cavity",
                    aliases: ["Abdominal cavity", "Peritoneal space"],
                    function: "The body cavity containing the major digestive organs (stomach, liver, intestines, spleen, pancreas, gallbladder); allows organ movement with minimal friction; lined by peritoneum which secretes serous fluid for lubrication",
                    commonConfusions: ["Peritoneal cavity vs thoracic cavity: diaphragm separates them — the peritoneal cavity is caudal/inferior to the diaphragm", "Intraperitoneal vs retroperitoneal: most digestive organs are intraperitoneal (within the peritoneal cavity); kidneys are retroperitoneal (behind the peritoneum)"],
                    examTips: ["Practical ID: the large abdominal space opened when the ventral abdominal wall is reflected", "HISTOLOGY KEY: peritoneal lining = mesothelium = simple squamous epithelium — optimized for low-friction lubrication, NOT abrasion protection", "Serous fluid in the cavity reduces friction between moving organs"],
                    histology: "Lined by mesothelium (simple squamous epithelium); serous fluid produced for lubrication and friction reduction between organs",
                    connections: "Surrounded by: diaphragm (cranial), pelvic inlet (caudal), abdominal wall (ventral/lateral), dorsal body wall (dorsal); contains stomach, liver, spleen, intestines, pancreas, gallbladder",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Umbilical Vein",
                    aliases: ["Umbilical venous trunk (abdominal portion)", "Fetal umbilical vein"],
                    function: "Fetal vessel carrying oxygenated blood and nutrients FROM the placenta TO the fetus; runs from umbilical cord along the ventral abdominal wall to the liver, where it joins the ductus venosus",
                    commonConfusions: ["Umbilical vein = oxygenated (unusual — veins normally carry deoxygenated blood); umbilical arteries = deoxygenated (unusual — arteries normally carry oxygenated blood)", "Single umbilical vein vs two umbilical arteries — the single larger vessel is the vein"],
                    examTips: ["Practical ID: large single vessel running along the ventral abdominal wall from the umbilical cord toward the liver", "FETAL TRACE: Placenta → umbilical vein → ductus venosus → caudal vena cava — VERY important fetal circulation route"],
                    histology: "Thin-walled vessel lined by simple squamous endothelium; no thick muscular wall (vein structure)",
                    connections: "Placenta → umbilical vein → ductus venosus → caudal vena cava → right atrium",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Liver",
                    aliases: ["Hepatic organ", "Hepatic lobe"],
                    function: "Metabolism, detoxification, storage, bile production",
                    commonConfusions: ["Largest internal organ; multiple lobes including right/left medial and lateral lobes"],
                    examTips: ["Dark reddish-brown color; occupies much of cranial abdomen"],
                    histology: "Hepatic parenchyma with portal circulation",
                    connections: "Receives umbilical vein (fetal); major organ",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Stomach",
                    aliases: ["Gastric sac", "Gaster", "Cardia", "Fundus", "Body/corpus", "Pyloric antrum"],
                    function: "Food storage, mechanical churning, acid secretion (HCl from parietal cells), enzyme secretion (pepsinogen from chief cells), and preliminary protein digestion. Divided into 4 regions: Cardiac (receives food from esophagus), Fundus/Body (major secretory site), Pyloric Antrum (regulates gastric emptying, secretes gastrin)",
                    commonConfusions: ["No villi — key distinction from small intestine on histology", "Stomach epithelium = simple columnar throughout (not stratified squamous like esophagus)", "Pyloric antrum vs pyloric sphincter: antrum is the stomach region; sphincter is the valve at the exit"],
                    examTips: ["Practical ID: J-shaped/sac-shaped organ cranial-left in the peritoneal cavity, between the esophagus and duodenum", "HISTOLOGY: gastric pits + glands, no villi, simple columnar epithelium", "Four regions are all testable: cardia, fundus, body/corpus, pyloric antrum"],
                    histology: "Simple columnar epithelium throughout; gastric pits leading to glands: cardiac glands (mucus), fundic glands (parietal cells = HCl; chief cells = pepsinogen), pyloric glands (mucus + G cells = gastrin); no villi",
                    connections: "Esophagus (via cardiac sphincter) → stomach → duodenum (via pyloric sphincter); lesser omentum attaches to liver",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Small Intestine",
                    aliases: ["Duodenum", "Jejunum", "Ileum"],
                    function: "Primary site of nutrient absorption",
                    commonConfusions: [],
                    examTips: ["Coiled loops; narrower than large intestine"],
                    histology: "Intestinal epithelium with villi and microvilli for absorption",
                    connections: "Stomach → small intestine → large intestine",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Kidney",
                    aliases: ["Renal organ", "Renal structure"],
                    function: "Filters blood, produces urine",
                    commonConfusions: ["Notable as retroperitoneal (not in peritoneal cavity proper)"],
                    examTips: ["Bean-shaped; usually paired structures"],
                    histology: "Renal filtration units",
                    connections: "Kidney → ureter → bladder",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Spleen",
                    aliases: ["Splenic organ", "Lien"],
                    function: "Largest lymphoid organ; filters blood by removing old, damaged, or abnormal red blood cells; performs immune surveillance; stores blood and platelets; produces lymphocytes for immune defense",
                    commonConfusions: ["Spleen vs liver: spleen is smaller, elongated/flattened, dark red-purple, on the LEFT; liver is large, multi-lobed, fills much of the cranial abdomen", "The spleen is ALWAYS on the animal's LEFT side — this is a navigation landmark for laterality during the practical"],
                    examTips: ["Practical ID: dark elongated flattened organ on the left side of the peritoneal cavity, near the stomach", "ORIENTATION TIP: spleen = always animal's LEFT side — if you find the spleen, you know which side you're on", "Histology: sinusoidal capillaries allow extensive blood-cell interaction and filtration"],
                    images: [
                        ImageCDN.image("spleen_gross_1.jpeg", caption: "Spleen"),
                        ImageCDN.image("spleen_gross_2.jpeg", caption: "Spleen"),
                    ],
                    histology: "Contains sinusoidal capillaries (discontinuous, for blood filtration); white pulp (lymphoid tissue = immune function); red pulp (blood filtration, RBC removal); trabecular capsule",
                    connections: "Receives blood from splenic artery (branch of celiac artery); drains via splenic vein → portal vein → liver; lies on animal's left, adjacent to stomach",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Peritoneum",
                    aliases: ["Serous membrane (abdominal)", "Peritoneal lining"],
                    function: "Serous membrane lining the abdominal cavity and covering many abdominal organs; reduces friction between organs, allows organ mobility, forms folds (mesenteries, omenta) that carry vessels/nerves/lymphatics, and compartmentalizes the abdomen",
                    commonConfusions: ["Peritoneum vs pleura: peritoneum = abdomen; pleura = lungs/thorax — both are serous membranes lined by simple squamous mesothelium", "Parietal peritoneum (body wall) vs visceral peritoneum (organ surface) — same tissue but different layers with different locations"],
                    examTips: ["MASTER CONCEPT: all serous membranes (peritoneum, pleura, pericardium) are lined by simple squamous mesothelium — this is VERY HIGH YIELD", "Thin shiny membrane visible on abdominal wall surfaces and organ surfaces", "Peritoneum forms folds: mesentery (suspends intestines), greater omentum (stomach apron), lesser omentum (liver-stomach)"],
                    histology: "Simple squamous mesothelium (mesothelial cells); underlying connective tissue; serous fluid secreted into peritoneal cavity for lubrication",
                    connections: "Parietal layer lines body wall; visceral layer covers organs (stomach, intestines, liver, spleen); forms mesentery, greater omentum, lesser omentum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Parietal Peritoneum",
                    aliases: ["Peritoneum parietale", "Abdominal wall lining"],
                    function: "The layer of peritoneum lining the inner surface of the abdominal body wall; forms the outer boundary of the peritoneal cavity; separates the peritoneal cavity from the retroperitoneal space",
                    commonConfusions: ["Parietal (wall lining) vs visceral (organ covering) — parietal is attached to the body wall, not to any organ", "Retroperitoneal organs (kidneys, most of duodenum) lie BEHIND the parietal peritoneum — they are not inside the peritoneal cavity"],
                    examTips: ["Practical ID: thin shiny membrane lining the inner abdominal wall, not directly on an organ", "KEY: kidneys are retroperitoneal = located behind the parietal peritoneum — this is a very testable relationship", "Parietal peritoneum → visceral peritoneum transition occurs at organ attachment points"],
                    histology: "Simple squamous mesothelium with underlying connective tissue; continuous with visceral peritoneum at organ attachment points",
                    connections: "Lines abdominal body wall; continuous with visceral peritoneum; forms peritoneal cavity between itself and visceral peritoneum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Visceral Peritoneum",
                    aliases: ["Peritoneum viscerale", "Serosa (abdominal organs)"],
                    function: "The layer of peritoneum directly covering abdominal organs; provides a smooth low-friction serous surface; equivalent to the serosa layer seen on the outer surface of GI histology slides",
                    commonConfusions: ["Visceral peritoneum = SEROSA — on GI histology slides, the outermost layer labeled 'serosa' IS the visceral peritoneum", "Not all organs have visceral peritoneum: retroperitoneal organs (kidneys, most of duodenum, esophagus) have ADVENTITIA instead of serosa/visceral peritoneum"],
                    examTips: ["EXAM TIP: visceral peritoneum = serosa of intraperitoneal organs — this connection is extremely testable in GI histology", "Organs WITH visceral peritoneum/serosa: stomach, most small intestine, most colon, liver, spleen", "Organs WITHOUT (have adventitia instead): esophagus, duodenum, kidneys, rectum"],
                    histology: "Simple squamous mesothelium; this is the outermost 'serosa' layer seen on GI tract histology slides for intraperitoneal organs",
                    connections: "Covers intraperitoneal organs; continuous with parietal peritoneum via mesenteric attachments; forms outer serosa layer of GI tract",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Greater Omentum",
                    aliases: ["Omentum majus", "Gastrocolic omentum", "Fatty apron"],
                    function: "Large apron-like fold of peritoneum extending from the greater curvature of the stomach and draping over the intestines; carries blood vessels, lymphatics, and nerves; stores adipose tissue; can migrate toward inflamed/infected areas to wall off infection ('policeman of the abdomen')",
                    commonConfusions: ["Greater omentum vs mesentery: mesentery suspends the intestines from the dorsal body wall; greater omentum is the fat-filled apron hanging from the stomach over the intestines", "Greater vs lesser omentum: greater = from stomach to drape over intestines; lesser = from liver to stomach/duodenum"],
                    examTips: ["Practical ID: fatty/lacy membrane hanging like an apron from the stomach over the intestines — may need to be reflected to see intestines beneath", "Simple squamous mesothelium surface (it is derived from peritoneum)", "Contains fat — can look yellow/cream colored in fetal pig"],
                    histology: "Double layer of peritoneum (simple squamous mesothelium) surrounding loose connective tissue with adipose, blood vessels, and lymphatics",
                    connections: "Attaches to greater curvature of stomach and drapes over intestines; connects to transverse colon (gastrocolic ligament portion); contains branches of gastroepiploic vessels",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: peritonealCat.id,
                    name: "Lesser Omentum",
                    aliases: ["Omentum minus", "Hepatogastric ligament", "Hepatoduodenal ligament"],
                    function: "Smaller peritoneal fold connecting the liver to the lesser curvature of the stomach (hepatogastric portion) and to the duodenum (hepatoduodenal portion); carries the portal triad structures (portal vein, hepatic artery, common bile duct) in its free edge",
                    commonConfusions: ["Lesser omentum carries the portal triad in its free (hepatoduodenal) edge — the hepatic portal vein, hepatic artery, and common bile duct all run through this", "Lesser vs greater omentum: lesser connects liver to stomach/duodenum; greater hangs from stomach over intestines"],
                    examTips: ["Practical ID: thin membrane between the liver and stomach/duodenum", "KEY: the free edge of the lesser omentum contains the portal vein + hepatic artery + common bile duct — a testable relationship"],
                    histology: "Double layer of peritoneum (simple squamous mesothelium) with connective tissue; contains the hepatoduodenal ligament carrying major vessels",
                    connections: "Liver → lesser omentum (hepatogastric) → lesser curvature of stomach; liver → lesser omentum (hepatoduodenal) → duodenum; free edge contains portal vein, hepatic artery, common bile duct",
                    highYield: false
                ),
            ])
        }

        // MARK: Buccal Cavity
        if let buccalCat = categories.first(where: { $0.name == "Buccal Cavity" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Mental Gland",
                    aliases: ["Cutaneous exocrine gland"],
                    function: "Secretes pheromones; chemical signals affecting behavior/physiology of other pigs",
                    commonConfusions: [],
                    examTips: ["Located near base of chin vibrissae (whisker region)"],
                    histology: "Exocrine gland; secretes through ducts onto body surface",
                    connections: "Duct secretion to body surface",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Tongue",
                    aliases: ["Lingual organ"],
                    function: "Mechanical manipulation of food, swallowing, taste sensation, positioning food, forming bolus, moving food into pharynx",
                    commonConfusions: [],
                    examTips: ["Occupies much of oral cavity floor; extends caudally toward oral pharynx"],
                    histology: "Stratified squamous epithelium on surface; contains skeletal muscle (striated, multinucleated), connective tissue, nerves, blood vessels, sensory receptors",
                    connections: "Tongue → oral cavity → oral pharynx → laryngeal pharynx/esophagus during swallowing",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Filiform Papillae",
                    aliases: ["Mechanical papillae"],
                    function: "Primarily mechanical; grip food, manipulate bolus, increase friction",
                    commonConfusions: ["Most numerous papillae; generally NOT gustatory"],
                    examTips: ["Tiny numerous rough papillae giving tongue textured appearance"],
                    histology: "Protective keratinized epithelium due to friction",
                    connections: "Cover much of tongue surface",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Fungiform Papillae",
                    aliases: ["Taste papillae"],
                    function: "Contain taste buds; participate in gustation",
                    commonConfusions: [],
                    examTips: ["Small mushroom-like papillae among other tongue papillae"],
                    histology: "Rounded projections with taste buds",
                    connections: "Scattered on tongue surface",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Vallate Papillae",
                    aliases: ["Circumvallate papillae"],
                    function: "Large papillae containing many taste buds; important gustatory structures",
                    commonConfusions: [],
                    examTips: ["Larger papillae near posterior tongue"],
                    histology: "Large papillae with trench-like surrounding grooves",
                    connections: "Located on posterior tongue",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Marginal Papillae",
                    aliases: ["Neonatal feeding papillae"],
                    function: "Help newborn mammals grip the nipple during nursing/suckling",
                    commonConfusions: ["Especially prominent in fetal pigs"],
                    examTips: ["Small projections along tongue edges in fetal specimens"],
                    histology: "Protective oral epithelium",
                    connections: "Located along tongue margins",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Incisive Papilla",
                    aliases: ["Hard palate papilla"],
                    function: "Associated with sensory/oral structures in anterior palate",
                    commonConfusions: [],
                    examTips: ["Small bump-like papilla near front hard palate"],
                    images: [
                        ImageCDN.image("incisive-papilla_gross_1.jpeg"),
                    ],
                    histology: "Protective oral epithelium: stratified squamous",
                    connections: "Just posterior to incisors on hard palate",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Oral Cavity",
                    aliases: ["Buccal cavity", "Mouth"],
                    function: "Mechanical digestion via chewing, bolus formation, initial chemical digestion via saliva, protection against pathogens",
                    commonConfusions: [],
                    examTips: ["Larger anterior chamber bounded by palate above and tongue below"],
                    histology: "Stratified squamous epithelium (HIGH YIELD); experiences friction, chewing stress, mechanical trauma, food abrasion",
                    connections: "Oral cavity → oral pharynx → laryngeal pharynx → esophagus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Hard Palate with Rugae",
                    aliases: ["Palate"],
                    function: "Rigid surface for tongue compression during chewing; separates oral from nasal cavity; rugae increase friction/grip for food",
                    commonConfusions: [],
                    examTips: ["Ridged rigid roof of mouth"],
                    images: [ImageCDN.image("hard-palate_gross_1.jpeg", caption: "Hard Palate with Rugae")],
                    histology: "Stratified squamous epithelium on surface; underlying bone for rigid support",
                    connections: "Dorsal to oral cavity; ventral to nasal cavity",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Soft Palate",
                    aliases: ["Velum palatinum"],
                    function: "During swallowing, elevates to block nasal passageways preventing food from entering nasal regions; directs airflow during breathing",
                    commonConfusions: ["Muscular/flexible, not bone-supported like hard palate"],
                    examTips: ["Smooth posterior flexible palate located caudal to hard palate/rugae"],
                    images: [ImageCDN.image("soft-palate_gross_1.jpeg", caption: "Soft Palate")],
                    histology: "Transition region; oral side: stratified squamous; nasal side: respiratory organization",
                    connections: "Hard palate → soft palate → pharyngeal regions",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Oral Pharynx",
                    aliases: ["Oropharynx"],
                    function: "Passageway for food bolus and air; part of swallowing pathway",
                    commonConfusions: ["Often confused with nasal pharynx and laryngeal pharynx"],
                    examTips: ["Located caudal to oral cavity, posterior to tongue, inferior to soft palate"],
                    histology: "Stratified squamous epithelium (abrasion exposure from food)",
                    connections: "Oral cavity → oral pharynx → laryngeal pharynx",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Laryngeal Pharynx",
                    aliases: ["Laryngopharynx"],
                    function: "Critical traffic-directing zone where food diverges to esophagus and air diverges to larynx/trachea",
                    commonConfusions: ["Most caudal pharynx; easy to confuse with other pharyngeal regions"],
                    examTips: ["Look near epiglottis, esophageal opening, laryngeal opening in sagittal sections"],
                    histology: "Stratified squamous epithelium (protective due to food abrasion and swallowing friction)",
                    connections: "Oral pharynx → laryngeal pharynx; then diverges to esophagus OR larynx/trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Entrance to Nasal Pharynx",
                    aliases: ["Nasopharyngeal entrance"],
                    function: "Allows airflow from nasal cavity → nasal pharynx → larynx/trachea",
                    commonConfusions: [],
                    examTips: ["Located dorsal/posterior to soft palate region"],
                    histology: "Pseudostratified ciliated columnar epithelium with goblet cells (VERY HIGH YIELD respiratory epithelium)",
                    connections: "External nostrils → nasal cavity → nasal pharynx → larynx → trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Nasal Pharynx",
                    aliases: ["Nasopharynx"],
                    function: "Conducts air from nasal cavity to larynx/trachea; primarily part of respiratory pathway",
                    commonConfusions: [],
                    examTips: ["Located dorsal/superior to soft palate, posterior to nasal cavity"],
                    histology: "Pseudostratified ciliated columnar epithelium with goblet cells and cilia; optimized for air conditioning",
                    connections: "Nasal cavity → nasal pharynx → larynx → trachea; soft palate separates from oral pathway",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Entrance to Esophagus",
                    aliases: ["Esophageal opening"],
                    function: "Passageway for swallowed food from pharynx into esophagus",
                    commonConfusions: [],
                    examTips: ["Located near laryngeal pharynx, posterior to airway opening"],
                    histology: "Stratified squamous epithelium (protective against abrasion from food)",
                    connections: "Pharynx → esophagus → stomach",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Epiglottis",
                    aliases: ["Arytenoid cartilage"],
                    function: "Critical airway protection; during swallowing, folds over glottis to prevent food/liquid entering airway",
                    commonConfusions: ["VERY IMPORTANT: distinguish epiglottis (flap) from glottis (opening)"],
                    examTips: ["Leaf-shaped cartilage flap at cranial end of larynx"],
                    histology: "Elastic cartilage core with connective tissue and mucosal lining; respiratory-facing: respiratory epithelium; food-contact: protective stratified squamous",
                    connections: "Laryngeal pharynx ↔ epiglottis ↔ glottis/larynx",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Hyoid Bone",
                    aliases: ["Os hyoid"],
                    function: "Provides anchoring points for muscles involved in swallowing, tongue movement, laryngeal elevation; stabilizes upper airway",
                    commonConfusions: ["Suspended support structure; doesn't articulate directly with other bones"],
                    examTips: ["Located in neck near tongue base, larynx, pharynx"],
                    histology: "Bone with connective and skeletal muscle attachments",
                    connections: "Tongue muscles ↔ hyoid ↔ laryngeal structures",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Parotid Gland",
                    aliases: ["Parotid salivary gland"],
                    function: "Produces saliva for lubrication, food softening, digestion, oral moisture",
                    commonConfusions: [],
                    examTips: ["Large obvious cheek/jaw muscle adjacent to parotid gland"],
                    histology: "Exocrine gland; secretory epithelial cells: cuboidal; duct epithelium: cuboidal",
                    connections: "Parotid gland → parotid duct → oral cavity",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Parotid Duct",
                    aliases: ["Stensen's duct"],
                    function: "Transports saliva from parotid gland into oral cavity",
                    commonConfusions: [],
                    examTips: ["Tube leaving parotid gland traveling toward oral cavity"],
                    histology: "Ductal epithelium: simple cuboidal",
                    connections: "Parotid gland → parotid duct → oral cavity",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Mandibular Gland",
                    aliases: ["Submandibular gland"],
                    function: "Produces saliva for lubrication, digestion, oral moisture",
                    commonConfusions: [],
                    examTips: ["Salivary gland near lower jaw/mandible"],
                    histology: "Exocrine gland; secretory epithelium: cuboidal/columnar; ducts: cuboidal epithelium",
                    connections: "Mandibular gland → salivary duct system → oral cavity",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Masseter Muscle",
                    aliases: ["Jaw muscle"],
                    function: "Primary muscle for jaw closing and chewing; generates bite force",
                    commonConfusions: [],
                    examTips: ["Large jaw muscle located lateral to mandible"],
                    histology: "Skeletal muscle (striated, multinucleated, peripheral nuclei)",
                    connections: "Located lateral to mandible",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Incisor Tooth",
                    aliases: ["Incisive tooth"],
                    function: "Cutting/shearing food; specialized for biting, clipping, initial mechanical processing",
                    commonConfusions: [],
                    examTips: ["Anterior tooth at front of mouth"],
                    histology: "Enamel, dentin, pulp cavity; surrounding: stratified squamous epithelium",
                    connections: "Within oral cavity",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Dorsal Branch of Facial Nerve",
                    aliases: ["Facial nerve branch"],
                    function: "Carries motor/sensory neural signals associated with facial structures",
                    commonConfusions: [],
                    examTips: ["Branch of facial nerve visible near parotid region"],
                    histology: "Nervous tissue (electrically excitable; specialized for signal transmission)",
                    connections: "Branches to innervate facial muscles/regions",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: buccalCat.id,
                    name: "Lymph Nodes",
                    aliases: ["Lymphatic nodes"],
                    function: "Immune surveillance and filtration of lymph; contain lymphocytes for immune cell interactions",
                    commonConfusions: [],
                    examTips: ["Small nodular immune structures associated with lymphatic vessels"],
                    histology: "Lymphocyte-rich immune connective tissue; packed with leukocytes, reticular support tissue",
                    connections: "Associated with lymphatic vessels",
                    highYield: false
                ),
            ])
        }
        
        
        // MARK: Upper Thoracic
        if let upperThoracicCat = categories.first(where: { $0.name == "Upper Thoracic" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Glottis",
                    aliases: ["Glottic opening"],
                    function: "Opening leading into larynx/trachea; controls airflow into lower respiratory tract",
                    commonConfusions: ["VERY IMPORTANT: glottis (opening) ≠ epiglottis (flap covering)"],
                    examTips: ["Opening immediately inferior/posterior to epiglottis"],
                    histology: "Associated with respiratory mucosa",
                    connections: "Pharynx → glottis → larynx → trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Larynx",
                    aliases: ["Voice box", "Laryngeal framework"],
                    function: "Air passage, airway protection with epiglottis, sound production via vocal folds",
                    commonConfusions: [],
                    examTips: ["Enlarged airway structure superior to trachea; oval-shaped protrusion"],
                    histology: "Pseudostratified ciliated columnar epithelium in respiratory regions; more protective stratified squamous on vocal folds",
                    connections: "Pharynx → larynx → trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Conchae",
                    aliases: ["Nasal turbinates", "Turbinal structures"],
                    function: "EXTREMELY important respiratory conditioning; increase surface area, warm air, humidify air, trap particles/pathogens",
                    commonConfusions: [],
                    examTips: ["Scroll-like/folded structures inside nasal cavity in sagittal sections"],
                    histology: "Pseudostratified ciliated columnar epithelium with goblet cells (VERY HIGH YIELD respiratory epithelium)",
                    connections: "External nostrils → nasal cavity/conchae → nasal pharynx → larynx → trachea",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Internal Nostril",
                    aliases: ["Choana"],
                    function: "Internal opening connecting nasal cavity to nasal pharynx; allows airflow into respiratory pathway",
                    commonConfusions: [],
                    examTips: ["Posterior opening of nasal cavity superior to soft palate"],
                    histology: "Pseudostratified ciliated columnar epithelium with goblet cells",
                    connections: "External nostril → nasal cavity → internal nostril → nasal pharynx",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Trachea",
                    aliases: ["Windpipe", "Tracheal tube"],
                    function: "Main airway tube conducting air from larynx to lungs; participates in air conditioning (warming, humidifying, filtering); maintains airway patency",
                    commonConfusions: ["Distinguished from esophagus by C-shaped cartilage rings"],
                    examTips: ["Obvious ringed tube; rigid appearance; ventral to esophagus"],
                    histology: "Pseudostratified ciliated columnar epithelium with goblet cells (VERY HIGH YIELD). Contains C-shaped hyaline cartilage rings for support",
                    connections: "Larynx → trachea → right/left bronchi",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Diaphragm",
                    aliases: ["Respiratory diaphragm"],
                    function: "Major muscle of mammalian respiration; contraction flattens it increasing thoracic volume drawing air in; relaxation expels air",
                    commonConfusions: ["Uniquely mammalian; skeletal muscle even though breathing often automatic"],
                    examTips: ["Thin muscular sheet beneath lungs/liver boundary; separates thoracic from abdominal cavity"],
                    histology: "Skeletal muscle (striated, multinucleated, peripheral nuclei); serosal coverings: pleura (superior), peritoneum (inferior); both lined by simple squamous mesothelium",
                    connections: "Thoracic cavity ↔ diaphragm ↔ abdominal cavity",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Esophagus",
                    aliases: ["Oesophagus", "Food tube"],
                    function: "Transports food bolus from pharynx to stomach via peristalsis",
                    commonConfusions: ["Distinguished from trachea by lack of cartilage rings and stratified squamous epithelium"],
                    examTips: ["Muscular tube posterior to trachea; absence of rings/cartilage"],
                    histology: "Stratified squamous epithelium (VERY HIGH YIELD); contains inner circular and outer longitudinal smooth muscle for peristalsis",
                    connections: "Pharynx → esophagus (passes through diaphragm at esophageal hiatus) → cardiac stomach; runs posterior to trachea in the mediastinum",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Thyroid Gland",
                    aliases: ["Thyroid", "Glandula thyroidea"],
                    function: "Produces thyroxine (T4) and triiodothyronine (T3), hormones that set the basal metabolic rate — essential for maintaining the high metabolism and heat production characteristic of mammals; also produces calcitonin for calcium regulation",
                    commonConfusions: ["Thyroid (endocrine, releases hormones into blood, no duct) vs thymus (lymphoid, T-cell maturation) — both are in the neck/thorax but completely different functions", "Thyroid is located near the LARYNX (caudal to it); thymus is more caudal in the MEDIASTINUM near the heart"],
                    examTips: ["Practical ID: compact, deep-red/purplish glandular mass located caudal to the larynx, covering/straddling the trachea in the cranial thorax/neck junction", "In fetal pigs it may appear as a small bilobed gland near the trachea", "Endocrine gland = secretes into blood, no duct; this is functionally different from salivary glands (exocrine, have ducts)"],
                    histology: "Follicular epithelium (simple cuboidal normally, flattened when inactive, columnar when active) surrounding colloid-filled follicles; colloid = thyroglobulin storage (precursor to T3/T4); parafollicular C cells produce calcitonin",
                    connections: "Located caudal to larynx, straddling the trachea; blood supply from superior and inferior thyroid arteries; drains into thyroid veins",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Thymus",
                    aliases: ["Thymic gland", "Primary lymphoid organ"],
                    function: "Site of T-lymphocyte maturation and selection — immature T-cells migrate from bone marrow to the thymus where they mature and are exported to peripheral lymphoid tissue; also secretes thymic hormones (thymosin) required for normal lymphoid development",
                    commonConfusions: ["Thymus vs thyroid: thymus is in the mediastinum near the heart (more caudal), thyroid is near the larynx; thymus = lymphoid/immune function, thyroid = metabolic hormone function", "The thymus is LARGE in fetal and neonatal life but involutes after puberty — in a fetal pig it is very prominent"],
                    examTips: ["Practical ID: large, pale, lobulated glandular mass in the cranial mediastinum, cranial to the heart; often extends into the neck region around the trachea in fetal pigs", "The lobulated pale appearance distinguishes it from the compact dark thyroid", "Fetal pig thymus is proportionally much larger than in adults — it involutes after birth"],
                    histology: "Cortex (dense thymocytes = immature T-cells) + medulla (lighter, contains Hassall's corpuscles = concentric epithelial whorls, a histological hallmark of thymus)",
                    connections: "Located in cranial mediastinum between sternum and great vessels; cranial extent reaches neck around trachea; thymocytes exit via blood to populate peripheral lymphoid organs",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Pleural Cavities",
                    aliases: ["Pleural cavity", "Right and left pleural cavities"],
                    function: "Right and left spaces within the thorax containing the lungs; pleural fluid provides a low-friction surface allowing lung expansion and contraction while maintaining the negative pressure that keeps lungs inflated",
                    commonConfusions: ["Pleural cavity (contains lungs) vs pericardial cavity (contains heart) — both are thoracic serous cavities but entirely separate", "The pleural cavities are separated from each other by the mediastinum; they do not communicate with each other"],
                    examTips: ["Practical ID: open the thorax — the spaces on either side of the mediastinum (heart/trachea region) are the pleural cavities containing the lungs", "Right and left pleural cavities are separated by the mediastinal septum", "Pneumothorax = air in the pleural cavity → lung collapses because negative pressure is lost"],
                    histology: "Lined by pleura = simple squamous mesothelium; visceral pleura covers lung surface; parietal pleura lines thoracic wall; pleural fluid between them reduces friction",
                    connections: "Right pleural cavity: right lung + surrounding space; left pleural cavity: left lung + pericardial sac medially; bounded by diaphragm (floor), ribs (wall), mediastinum (medial)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Pericardial Cavity",
                    aliases: ["Pericardial space", "Space around the heart"],
                    function: "The space between the visceral and parietal layers of the pericardium surrounding the heart; contains a small amount of pericardial fluid that lubricates the beating heart and reduces friction during each heartbeat",
                    commonConfusions: ["Pericardial cavity (around heart) vs pleural cavities (around lungs) — both are serous-lined spaces but separate", "Pericardial effusion = excess fluid in pericardial cavity → can compress heart (cardiac tamponade)"],
                    examTips: ["Practical ID: the space immediately around the heart, inside the pericardial sac/wall", "The heart is described as lying behind the transparent pericardial wall — look through or open the pericardial sac to see the heart in the pericardial cavity"],
                    histology: "Lined by pericardium = simple squamous mesothelium; visceral pericardium = epicardium on heart surface; parietal pericardium = inner surface of pericardial sac",
                    connections: "Surrounds heart; pericardial sac anchored to great vessels above and diaphragm below; lies within mediastinum between the two pleural cavities",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Mediastinum",
                    aliases: ["Mediastinal septum", "Mediastinal partition", "Central thoracic compartment"],
                    function: "The central compartment of the thoracic cavity situated between the right and left pleural cavities; essentially the space between the lungs; contains and supports the heart, pericardial cavity, thymus, trachea, esophagus, major blood vessels, vagus and phrenic nerves, and lymphatic structures; acts as conduit for vessels, nerves, and lymphatics passing between thorax and neck/abdomen",
                    commonConfusions: ["Mediastinum ≠ a single membrane — it is a thick three-dimensional region of tissue and organs between the lungs, not just a partition", "Mediastinum vs pleural cavities: pleural cavities contain the lungs; the mediastinum contains everything between them (heart, trachea, esophagus, thymus, great vessels)", "The handout refers to the 'mediastinal septum' — this is the same as the mediastinum in the context of fetal pig dissection"],
                    examTips: ["Practical ID: when the thorax is opened and the lungs are spread to each side, the mediastinum is the central mass of tissue between them — you will see the pericardial sac (heart), trachea, and thymus here", "IN FETAL PIG: the thymus is disproportionately LARGE in the mediastinum — a prominent identifying feature", "Mediastinum contains: heart + pericardial cavity, thymus, trachea, esophagus, aortic arch, cranial/caudal vena cava, pulmonary trunk"],
                    histology: "Not a single tissue type — a composite region containing cardiac muscle (heart), hyaline cartilage (trachea rings), connective tissue (stroma), serous mesothelium (pericardial and pleural surfaces), smooth muscle (esophagus, vessels), and lymphoid tissue (thymus); pericardial and pleural surfaces = simple squamous mesothelium",
                    connections: "Bounded by: sternum (ventral), vertebral column (dorsal), thoracic inlet (cranial), diaphragm (caudal), right and left parietal pleura (lateral); contains: heart in pericardial sac, trachea bifurcating to bronchi, esophagus, aortic arch and great vessels, thymus",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Pericardial Wall",
                    aliases: ["Pericardial sac", "Pericardium", "Parietal pericardium"],
                    function: "Tough fibroserous sac surrounding the heart; protects the heart from infection and overdistension; anchors it in the mediastinum; the transparent membrane visible in dissection before you reach the heart",
                    commonConfusions: ["Pericardial wall = pericardial sac = the covering of the heart; different from the pericardial CAVITY (the space inside it)", "Two layers: fibrous pericardium (tough outer) + serous pericardium (smooth inner lining = visceral layer, epicardium, on heart)"],
                    examTips: ["Practical ID: in thoracic dissection, the transparent/translucent membrane you see before reaching the heart is the pericardial wall/sac", "The handout describes 'the heart lying behind the transparent pericardial wall'", "Open/cut the pericardial sac to enter the pericardial cavity and access the heart"],
                    histology: "Outer fibrous pericardium: dense irregular connective tissue; Inner serous pericardium: simple squamous mesothelium with underlying connective tissue; pericardial fluid in cavity",
                    connections: "Surrounds heart and proximal great vessels; fused with central tendon of diaphragm; fibrous layer fuses with adventitia of ascending aorta and pulmonary trunk",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Parietal Pericardium",
                    aliases: ["Fibroserous pericardium", "Outer pericardial layer"],
                    function: "The outer layer of the pericardium; forms the inner lining of the pericardial sac; consists of an outer tough fibrous layer (fibrous pericardium) and an inner serous layer; together they create the pericardial cavity",
                    commonConfusions: ["Parietal pericardium is the sac wall; visceral pericardium (epicardium) is on the heart surface — same pattern as parietal/visceral peritoneum and pleura", "The inner surface of the pericardial sac = parietal serous pericardium (simple squamous mesothelium)"],
                    examTips: ["COMPARISON: Parietal pericardium (heart sac) = parietal pleura (thoracic wall) = parietal peritoneum (abdominal wall) — all line the body cavity wall around their respective organ", "All lined by simple squamous mesothelium"],
                    histology: "Inner surface: simple squamous mesothelium (serous pericardium); outer layer: dense irregular connective tissue (fibrous pericardium)",
                    connections: "Forms pericardial sac; inner surface faces pericardial cavity; continuous with visceral pericardium (epicardium) at great vessel reflections",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: upperThoracicCat.id,
                    name: "Visceral Pericardium",
                    aliases: ["Epicardium", "Visceral pericardial layer", "Outer heart layer"],
                    function: "The inner layer of the pericardium that directly covers the heart surface (epicardium); serous membrane allowing the heart to beat smoothly within the pericardial sac; the outermost of the three heart layers (epicardium, myocardium, endocardium)",
                    commonConfusions: ["Visceral pericardium = epicardium — these are the same structure (two names for the serous layer on the heart surface)", "Epicardium vs endocardium: epicardium = outer (serous membrane); endocardium = inner (lines the heart chambers)", "Three heart wall layers: epicardium (outer, serous) → myocardium (middle, cardiac muscle) → endocardium (inner, simple squamous)"],
                    examTips: ["MASTER TABLE: visceral pericardium (heart) = visceral pleura (lungs) = visceral peritoneum (abdominal organs) — all are simple squamous mesothelium covering the organ directly", "On histology slides of the heart wall: outermost layer = epicardium/visceral pericardium (simple squamous); middle = myocardium (cardiac muscle); innermost = endocardium (simple squamous endothelium)"],
                    histology: "Simple squamous mesothelium (serous pericardium); directly adheres to underlying myocardium; may contain adipose tissue in the subepicardial space",
                    connections: "Directly covers heart surface; continuous with parietal pericardium at great vessel reflections; lies over myocardium; pericardial cavity between visceral and parietal layers",
                    highYield: true
                ),
            ])
        }

        // MARK: Urinary System additional structures
        if let urinaryCat2 = categories.first(where: { $0.name == "Urinary System" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: urinaryCat2.id,
                    name: "Ureter",
                    aliases: ["Ureteral tube", "Ureteres"],
                    function: "Paired muscular tubes that transport urine from each kidney to the urinary bladder via peristaltic contractions; one ureter per kidney",
                    commonConfusions: ["Ureter (kidney → bladder) vs urethra (bladder → outside); students commonly confuse these — ureTER has two e's like 'kidney to bladder'; ureTHRA has an h like 'here it exits'", "Ureters enter the bladder at an angle creating a one-way valve (vesicoureteral junction) — prevents backflow of urine"],
                    examTips: ["Practical ID: slender white tubes running retroperitoneally from each kidney caudally toward the bladder", "In fetal pig: trace from the renal hilum caudally to where they insert into the dorsal bladder wall", "The ureters cross ventral to the iliac vessels in their course to the bladder"],
                    histology: "Transitional epithelium (urothelium) lining; muscularis of inner longitudinal + outer circular smooth muscle (opposite of GI tract); adventitia outer layer",
                    connections: "Renal pelvis (in kidney) → ureter → urinary bladder (posterior wall); bilateral; retroperitoneal course along dorsal body wall",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: urinaryCat2.id,
                    name: "Urinary Bladder",
                    aliases: ["Bladder", "Vesica urinaria", "Urinary reservoir"],
                    function: "Muscular expandable sac that temporarily stores urine received from the ureters until voluntary micturition (urination); can expand dramatically to accommodate increasing urine volume",
                    commonConfusions: ["Urinary bladder vs gallbladder — both are 'bladders' (expandable sacs) but completely different systems; urinary bladder stores urine, gallbladder stores bile", "The fetal pig bladder connects to the allantoic stalk (urachus) at its apex — a developmental remnant unique to fetal life"],
                    examTips: ["Practical ID: thin-walled, expandable sac in the caudal abdomen/pelvic region, often found between the umbilical arteries in fetal pig", "In fetal pigs, the apex of the bladder connects to the allantoic stalk (urachus) which leads to the allantois through the umbilical cord", "HIGH YIELD HISTOLOGY: lined by transitional epithelium (urothelium) — the only epithelium that can stretch dramatically without tearing"],
                    histology: "Transitional epithelium (urothelium) — multiple layers; surface 'umbrella cells' are large dome-shaped cells that flatten dramatically during bladder filling; smooth muscle wall = detrusor muscle (three layers); adventitia or serosa on outside",
                    connections: "Receives: two ureters (from kidneys); drains via: urethra → exterior; in fetal pigs: apex connects to urachus/allantoic stalk → allantois; located in caudal abdominal/pelvic region between umbilical arteries",
                    highYield: true
                ),
            ])
        }

        // MARK: Epithelial Types
        if let epithelialCat = categories.first(where: { $0.name == "Epithelial Types" }) {
            structures.append(contentsOf: [
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Simple Squamous Epithelium",
                    aliases: ["Squamous simple"],
                    function: "Allows rapid diffusion and filtration; reduces friction in body cavities; minimal barrier to exchange",
                    commonConfusions: ["Do not confuse with stratified squamous — 'simple' means single layer only"],
                    examTips: ["Found wherever diffusion/filtration/lubrication is the priority", "Key locations: alveoli (gas exchange), blood/lymph vessel endothelium, Bowman's capsule, mesothelium of pleura/peritoneum/pericardium", "Single flat layer — like floor tiles viewed from above"],
                    histology: "Single layer of flat, scale-like cells; nucleus bulges into lumen; very thin for rapid exchange",
                    connections: "Alveoli, endothelium (all vessels), Bowman's capsule, mesothelium of pleura/peritoneum/pericardium, loop of Henle thin segment",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Simple Cuboidal Epithelium",
                    aliases: ["Cuboidal simple"],
                    function: "Secretion and absorption in glands and tubules; forms much of the kidney tubule system",
                    commonConfusions: [],
                    examTips: ["Key locations: kidney tubules (proximal and distal convoluted tubules), thyroid follicles, small ducts of glands", "Cube-shaped cells with round central nuclei — height ≈ width"],
                    histology: "Single layer of roughly cube-shaped cells; round central nucleus; moderate cytoplasm for metabolic activity",
                    connections: "Kidney tubules (PCT, DCT), thyroid follicles, small exocrine gland ducts, ovarian surface",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Simple Columnar Epithelium",
                    aliases: ["Columnar simple"],
                    function: "Secretion and absorption; lines much of the digestive tract where absorption is the primary role",
                    commonConfusions: ["Ciliated simple columnar found in uterine tube/oviduct — not to be confused with pseudostratified columnar of trachea"],
                    examTips: ["Key locations: stomach, small intestine (with microvilli for absorption), large intestine, gallbladder, uterine tube", "Tall cells taller than wide; oval nucleus near base"],
                    histology: "Single layer of tall rectangular cells; oval nucleus near the base; may have microvilli (brush border) for absorption or goblet cells for mucus",
                    connections: "Stomach, small intestine, large intestine, gallbladder, bile ducts, uterine tube (oviduct)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Pseudostratified Columnar Epithelium",
                    aliases: ["Pseudostratified ciliated columnar", "Respiratory epithelium"],
                    function: "Secretes mucus (goblet cells) and moves it via cilia — classic 'mucociliary escalator' that traps and removes particles/pathogens; air conditioning of inspired air",
                    commonConfusions: ["NOT truly stratified — all cells contact the basement membrane; nuclei at different heights create the false appearance of layers", "Ciliated pseudostratified = respiratory epithelium; non-ciliated pseudostratified = epididymis (with stereocilia)"],
                    examTips: ["VERY HIGH YIELD — appears on almost every practical", "Key locations: trachea, bronchi, nasal cavity, nasal pharynx, conchae/turbinates", "Has goblet cells (mucus) + cilia (movement) — the mucociliary escalator", "All cells touch basement membrane; only some reach the lumen — that's why nuclei look layered"],
                    histology: "Single layer but nuclei at varying heights giving false multilayer appearance; ciliated (motile) + goblet cells (mucus secreting); all cells on basement membrane",
                    connections: "Trachea, bronchi, nasal cavity, nasal pharynx, nasopharynx, conchae (turbinates), Eustachian tube",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Stratified Squamous Epithelium (Nonkeratinized)",
                    aliases: ["Stratified squamous non-keratinized", "Moist stratified squamous"],
                    function: "Protection against abrasion in moist internal surfaces; maintains barrier without sacrificing flexibility or transparency",
                    commonConfusions: ["Nonkeratinized = moist, flexible, transparent; Keratinized = dry, tough, waterproof (like skin)"],
                    examTips: ["Key locations: oral cavity, esophagus, vagina, cornea (transparent variant)", "Esophagus is VERY HIGH YIELD — always stratified squamous, contrasts with pseudostratified columnar of trachea", "Cornea: nonkeratinized to maintain transparency"],
                    histology: "Multiple layers; surface cells are flat (squamous); basal layer cuboidal/columnar; no keratin (surface cells remain nucleated and moist)",
                    connections: "Oral cavity, esophagus (entire length), vagina, cornea, anal canal (upper portion)",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Stratified Squamous Epithelium (Keratinized)",
                    aliases: ["Keratinized stratified squamous", "Skin epithelium", "Epidermis"],
                    function: "Provides tough, waterproof, abrasion-resistant barrier against the external environment; prevents desiccation",
                    commonConfusions: ["Keratinized = dry surface cells are dead and filled with keratin; found on EXTERNAL dry surfaces only"],
                    examTips: ["Key locations: skin (epidermis), external surface of lips, hard palate, gingiva", "Surface cells are dead, anucleate, and filled with keratin protein"],
                    histology: "Multiple layers; surface cells are dead, anucleate, filled with keratin (waterproof protein); thick and tough",
                    connections: "Epidermis (all external skin), external lip surface, hard palate, gingiva (gums)",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Stratified Cuboidal Epithelium",
                    aliases: ["Cuboidal stratified"],
                    function: "Lines larger ducts of sweat glands and some other exocrine glands; provides protection with modest secretory capacity",
                    commonConfusions: [],
                    examTips: ["Relatively rare — mainly large sweat gland ducts and some salivary gland ducts", "Two or more layers of cuboidal cells"],
                    histology: "Two or more layers of cube-shaped cells; less common than simple or stratified squamous",
                    connections: "Large excretory ducts of sweat glands, some salivary gland ducts",
                    highYield: false
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Transitional Epithelium",
                    aliases: ["Urothelium", "Transitional urothelium"],
                    function: "Lines the urinary tract; can stretch enormously as the bladder fills and return to thicker appearance when empty",
                    commonConfusions: ["Only found in urinary tract — its stretchability is unique to this epithelium type"],
                    examTips: ["Key locations: bladder (entire), ureters, urethra (proximal portion), renal pelvis", "Dome-shaped surface cells (umbrella cells) when relaxed; flattened when distended", "Stretchability is its defining functional feature"],
                    histology: "Multiple layers; surface cells are large, dome-shaped 'umbrella cells' that flatten when bladder stretches; intermediate layers allow sliding movement",
                    connections: "Renal pelvis, ureters, urinary bladder, proximal urethra",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Pseudostratified Columnar Epithelium (Non-Ciliated)",
                    aliases: ["Epididymal epithelium", "Pseudostratified with stereocilia"],
                    function: "Lines epididymis; stereocilia support sperm maturation and absorption — NOT for movement",
                    commonConfusions: ["VERY IMPORTANT DISTINCTION: stereocilia are NONMOTILE long microvilli (absorptive); true cilia are MOTILE (respiratory epithelium). Both called 'cilia' but function completely differently", "Non-ciliated pseudostratified (epididymis) vs ciliated pseudostratified (trachea) — do not confuse"],
                    examTips: ["Found in epididymis and vas deferens (proximal portion)", "Stereocilia = long, nonmotile microvilli; absorptive, not motility-related", "This is the ONLY main location of pseudostratified non-ciliated columnar in the body"],
                    histology: "Pseudostratified columnar with stereocilia (long nonmotile microvilli); all cells contact basement membrane; principal cells and basal cells present",
                    connections: "Epididymis, proximal vas deferens",
                    highYield: true
                ),
                AnatomyStructure(
                    categoryId: epithelialCat.id,
                    name: "Epithelial Type Quick Reference",
                    aliases: ["Epithelial summary", "Epithelium locations"],
                    function: "Summary of all epithelial types and their key locations for rapid review",
                    commonConfusions: ["The naming rule: Simple = 1 layer; Stratified = multiple layers; Pseudo = looks stratified but is actually 1 layer"],
                    examTips: [
                        "Alveoli → Simple squamous (diffusion)",
                        "All blood/lymph vessel endothelium → Simple squamous",
                        "Mesothelium (pleura/peritoneum/pericardium) → Simple squamous",
                        "Kidney tubules (PCT/DCT) → Simple cuboidal",
                        "Stomach/intestine/gallbladder → Simple columnar",
                        "Trachea/bronchi/nasal cavity → Pseudostratified ciliated columnar (respiratory epithelium)",
                        "Epididymis → Pseudostratified columnar with stereocilia (nonmotile)",
                        "Esophagus/oral cavity/vagina/cornea → Stratified squamous nonkeratinized",
                        "Skin epidermis → Stratified squamous keratinized",
                        "Bladder/ureters → Transitional (urothelium)"
                    ],
                    histology: "See individual epithelial type entries for detailed histology",
                    connections: "Cross-reference with specific organ entries for clinical and practical context",
                    highYield: true
                ),
            ])
        }

        return structures
    }
    
    // MARK: - Query Methods
    
    func structures(in category: AnatomyCategory) -> [AnatomyStructure] {
        return structures.filter { $0.categoryId == category.id }
    }

    /// All structures in the same order they appear in the Atlas
    /// (Terminology → Gross Anatomy → Histology → Microscope → Epithelial Types,
    ///  categories in atlas order, structures in their original insertion order).
    var orderedStructures: [AnatomyStructure] {
        let atlasOrder: [String] = [
            // Terminology
            "Anatomical Planes", "Directional Terminology",
            // Gross Anatomy
            "External", "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
            "Digestive System", "Respiratory System", "Circulatory System",
            "Urinary System", "Male Reproductive", "Female Reproductive",
            "Fetal Structures", "Adult Maternal Pig", "Cow Eye",
            // Histology
            "Blood Histology", "Vessel Histology", "Respiratory Histology",
            "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
            "Kidney Histology", "Reproductive Histology",
            // Microscope
            "Microscope",
            // Epithelial Types
            "Epithelial Types"
        ]
        return atlasOrder.compactMap { name in
            categories.first { $0.name == name }
        }.flatMap { structures(in: $0) }
    }
    
    func structure(named name: String) -> AnatomyStructure? {
        return structures.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func searchStructures(query: String) -> [AnatomyStructure] {
        let lowercaseQuery = query.lowercased()
        return structures.filter { structure in
            structure.name.lowercased().contains(lowercaseQuery) ||
            structure.aliases.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    func randomStructures(count: Int, excluding: [AnatomyStructure] = []) -> [AnatomyStructure] {
        let available = structures.filter { !excluding.contains($0) }
        return Array(available.shuffled().prefix(count))
    }

    func traces(in category: String) -> [TraceQuestion] {
        traces.filter { $0.category == category }
    }

    var traceCategories: [String] {
        Array(Set(traces.map { $0.category })).sorted()
    }

    // MARK: - Trace Data

    private func createTraces() -> [TraceQuestion] {
        return [

            // MARK: Digestive + Circulatory Trace
            TraceQuestion(
                title: "Carbohydrate: Mouth → Right Shoulder Muscle",
                scenario: "Trace the path a carbohydrate from a strawberry would take from an adult male pig's mouth to the muscle in his right shoulder.",
                category: "Digestive + Circulatory",
                steps: [
                    TraceStep("Oral Cavity", highlight: true),
                    TraceStep("Right Parotid Gland + Mandibular Gland (salivary glands)"),
                    TraceStep("Serous Acinar Cells → Salivary α-Amylase secreted (begins starch breakdown)"),
                    TraceStep("Right Parotid Duct + Mandibular Duct → Oral cavity"),
                    TraceStep("Oral Pharynx", highlight: true),
                    TraceStep("Laryngeal Pharynx"),
                    TraceStep("Upper Esophageal Sphincter (UES)"),
                    TraceStep("Esophagus", highlight: true),
                    TraceStep("Lower Esophageal Sphincter (LES) / Cardiac Sphincter"),
                    TraceStep("Cardiac Stomach → Fundus → Body (Corpus) → Pyloric Antrum"),
                    TraceStep("Pyloric Sphincter"),
                    TraceStep("Duodenum", highlight: true),
                    TraceStep("Exocrine Pancreas → Acinar Cells → Pancreatic Amylase secreted"),
                    TraceStep("Pancreatic Duct → Common Bile Duct (+ accessory duct without Sphincter of Oddi)"),
                    TraceStep("Sphincter of Oddi → Duodenum"),
                    TraceStep("Jejunum", highlight: true),
                    TraceStep("Jejunal Villi → Enterocytes → Brush Border Enzymes (Maltase, Sucrase, Lactase)"),
                    TraceStep("→ Final breakdown into Glucose"),
                    TraceStep("Glucose absorbed → Diffusion through Enterocytes"),
                    TraceStep("Jejunal Capillaries (within villi)", highlight: true),
                    TraceStep("Mesenteric Venules → Mesenteric Vein"),
                    TraceStep("Hepatic Portal Vein", highlight: true),
                    TraceStep("Branches of Hepatic Portal Vein → Liver Sinusoids"),
                    TraceStep("Contact with Hepatocytes → Central Vein → Hepatic Vein"),
                    TraceStep("Caudal Vena Cava", highlight: true),
                    TraceStep("Right Atrium → Tricuspid Valve → Right Ventricle"),
                    TraceStep("Pulmonary Semilunar Valve → Pulmonary Trunk"),
                    TraceStep("Right Pulmonary Artery → Right Pulmonary Arterioles → Right Pulmonary Capillaries"),
                    TraceStep("Right Pulmonary Venule → Right Pulmonary Veins → Left Atrium"),
                    TraceStep("Bicuspid (Mitral) Valve → Left Ventricle", highlight: true),
                    TraceStep("Aortic Semilunar Valve → Ascending Aorta → Arch of the Aorta"),
                    TraceStep("Brachiocephalic Trunk → Right Subclavian Artery", highlight: true),
                    TraceStep("Right Subscapular Artery → Right Subscapular Arterioles"),
                    TraceStep("Right Subscapular Capillaries → Diffusion through capillary endothelium"),
                    TraceStep("Right Shoulder Muscle", highlight: true),
                ],
                keyPoints: [
                    "Don't forget salivary amylase begins digestion before the stomach",
                    "Pyloric sphincter controls stomach emptying into duodenum",
                    "Pancreatic amylase enters via pancreatic duct + Sphincter of Oddi",
                    "Final glucose breakdown by brush border enzymes on jejunal villi enterocytes",
                    "Absorbed glucose goes: portal vein → liver → systemic circulation (NOT directly to heart)",
                    "Tri before Bi: blood passes TRIcuspid first, then BIcuspid (mitral) valve",
                    "Right subclavian → subscapular artery (NOT direct from brachiocephalic to shoulder)",
                ],
                highYield: true
            ),

            // MARK: Fetal Circulation
            TraceQuestion(
                title: "Fetal: Oxygen from Placenta → Fetal Brain",
                scenario: "Trace oxygenated blood from the placenta to the fetal brain, including all three fetal bypass routes.",
                category: "Fetal Circulation",
                steps: [
                    TraceStep("Placenta (gas + nutrient exchange)", highlight: true),
                    TraceStep("Umbilical Vein (single, oxygenated, thin-walled)", highlight: true),
                    TraceStep("→ Liver (partial perfusion)"),
                    TraceStep("Ductus Venosus (Bypass #1: bypasses liver)", highlight: true),
                    TraceStep("Caudal Vena Cava"),
                    TraceStep("Right Atrium"),
                    TraceStep("Foramen Ovale (Bypass #2: right atrium → left atrium, bypasses lungs)", highlight: true),
                    TraceStep("Left Atrium → Bicuspid Valve → Left Ventricle"),
                    TraceStep("Aortic Valve → Ascending Aorta → Arch of Aorta"),
                    TraceStep("Common Carotid Arteries → Brain", highlight: true),
                    TraceStep("--- Note: remaining right atrial blood ---"),
                    TraceStep("Right Ventricle → Pulmonary Trunk"),
                    TraceStep("Ductus Arteriosus (Bypass #3: pulmonary trunk → aorta, bypasses lungs)", highlight: true),
                    TraceStep("Descending Aorta → Systemic fetal circulation"),
                    TraceStep("Internal Iliac Arteries → Umbilical Arteries (deoxygenated, back to placenta)"),
                ],
                keyPoints: [
                    "Three fetal shunts: ductus venosus, foramen ovale, ductus arteriosus",
                    "All three shunts bypass the nonfunctional fetal lungs",
                    "Umbilical vein = single, carries oxygenated blood FROM placenta",
                    "Umbilical arteries = paired, carry deoxygenated blood TO placenta",
                    "Ductus venosus → ligamentum venosum after birth",
                    "Foramen ovale → fossa ovalis after birth",
                    "Ductus arteriosus → ligamentum arteriosum after birth",
                ],
                highYield: true
            ),

            // MARK: Maternal-to-Fetal
            TraceQuestion(
                title: "Maternal-to-Fetal Circulatory Exchange",
                scenario: "Trace the path of oxygen from the maternal aorta to the fetal bloodstream via the placenta.",
                category: "Fetal Circulation",
                steps: [
                    TraceStep("Maternal Descending Aorta", highlight: true),
                    TraceStep("Internal Iliac Artery (OFTEN FORGOTTEN on exams)", highlight: true),
                    TraceStep("Uterine Artery → Uterine Arterioles"),
                    TraceStep("Maternal Placental Capillaries"),
                    TraceStep("Uterine Epithelium Barrier (maternal/fetal blood do NOT mix directly)"),
                    TraceStep("Chorioallantoic Membrane (exchange surface)", highlight: true),
                    TraceStep("Fetal Capillaries → Umbilical Venules"),
                    TraceStep("Umbilical Vein → Ductus Venosus → Caudal Vena Cava", highlight: true),
                ],
                keyPoints: [
                    "Internal iliac artery is the most commonly forgotten step",
                    "Maternal and fetal blood do NOT directly mix — separated by tissue barriers",
                    "The chorioallantoic membrane is the actual exchange surface",
                    "Exchange is: O2/nutrients from maternal to fetal; CO2/waste from fetal to maternal",
                ],
                highYield: true
            ),

            // MARK: Portal Circulation
            TraceQuestion(
                title: "Absorbed Nutrient: Intestine → Systemic Circulation via Liver",
                scenario: "Trace the path of an absorbed nutrient from intestinal capillaries back to the systemic venous system, through the liver.",
                category: "Digestive + Circulatory",
                steps: [
                    TraceStep("Intestinal Capillaries (within villi)", highlight: true),
                    TraceStep("Mesenteric Venules → Mesenteric Vein"),
                    TraceStep("Hepatic Portal Vein", highlight: true),
                    TraceStep("Branches of Hepatic Portal Vein (+ Hepatic Artery branches)"),
                    TraceStep("Liver Sinusoids (highly permeable capillaries)", highlight: true),
                    TraceStep("Contact with Hepatocytes (processing, detoxification, storage)"),
                    TraceStep("Central Vein → Hepatic Vein"),
                    TraceStep("Caudal Vena Cava → Right Atrium", highlight: true),
                ],
                keyPoints: [
                    "The portal system connects two capillary beds: GI capillaries and liver sinusoids",
                    "Liver sinusoids are discontinuous/highly permeable — ideal for hepatocyte processing",
                    "Hepatic artery ALSO supplies liver (oxygenated blood), distinct from portal vein",
                    "All absorbed GI nutrients pass through liver before reaching systemic circulation",
                ],
                highYield: true
            ),

            // MARK: Oxygen: Nasal Cavity → Alveoli
            TraceQuestion(
                title: "Oxygen: External Naris → Alveolar Gas Exchange",
                scenario: "Trace the path of an oxygen molecule from the external nostril to the alveolar capillaries where gas exchange occurs.",
                category: "Respiratory",
                steps: [
                    TraceStep("External Nostril (Naris)", highlight: true),
                    TraceStep("Nasal Cavity / Conchae (turbinates) — warming, humidifying, filtering"),
                    TraceStep("Internal Nostril (Choana)"),
                    TraceStep("Nasal Pharynx (Nasopharynx)", highlight: true),
                    TraceStep("Laryngeal Pharynx → Glottis (opening to larynx)"),
                    TraceStep("Larynx (voice box, airway protection)"),
                    TraceStep("Trachea (C-shaped cartilage rings; pseudostratified ciliated columnar epithelium)", highlight: true),
                    TraceStep("Left/Right Bronchi (cartilage rings; pseudostratified ciliated columnar)"),
                    TraceStep("Bronchioles (no cartilage; pseudostratified/simple columnar)"),
                    TraceStep("Alveolar Ducts → Alveolar Sacs → Alveoli", highlight: true),
                    TraceStep("Simple Squamous Epithelium of alveolar wall"),
                    TraceStep("Diffusion across alveolar wall + capillary endothelium → Pulmonary Capillaries"),
                ],
                keyPoints: [
                    "Conchae are critical for air conditioning — very high yield",
                    "Trachea vs esophagus: trachea has C-shaped cartilage rings + pseudostratified epithelium; esophagus has no rings + stratified squamous",
                    "Bronchi have cartilage; bronchioles do NOT",
                    "Gas exchange at alveoli: simple squamous epithelium for minimal diffusion distance",
                    "Glottis = opening; epiglottis = flap covering — do not confuse",
                ],
                highYield: true
            ),

            // MARK: Urine Formation
            TraceQuestion(
                title: "Blood Filtrate: Renal Artery → Urine Excreted",
                scenario: "Trace the path of blood from the renal artery through nephron filtration to final urine excretion.",
                category: "Renal",
                steps: [
                    TraceStep("Renal Artery → Afferent Arteriole", highlight: true),
                    TraceStep("Glomerulus (ultrafiltration — blood pressure drives filtrate out)"),
                    TraceStep("Bowman's Capsule (receives filtrate)", highlight: true),
                    TraceStep("Proximal Convoluted Tubule — PCT (major reabsorption: glucose, amino acids, Na+)"),
                    TraceStep("Loop of Henle — descending and ascending limbs (concentration gradient)"),
                    TraceStep("Distal Convoluted Tubule — DCT (hormone-regulated fine-tuning)"),
                    TraceStep("Collecting Duct → Renal Pelvis", highlight: true),
                    TraceStep("Ureter → Urinary Bladder → Urethra → External environment"),
                ],
                keyPoints: [
                    "Glomerulus filters by pressure; Bowman's capsule collects the filtrate",
                    "PCT: simple cuboidal epithelium with microvilli (high surface area for reabsorption)",
                    "Collecting duct → renal pelvis → ureter → bladder → urethra",
                    "Bladder epithelium: transitional (urothelium) — can stretch",
                ],
                highYield: true
            ),

            // MARK: Sperm to Ejaculation
            TraceQuestion(
                title: "Sperm: Seminiferous Tubule → Ejaculation",
                scenario: "Trace the path of a sperm cell from its production site to the point of ejaculation.",
                category: "Reproductive",
                steps: [
                    TraceStep("Seminiferous Tubules (sperm production via spermatogenesis)", highlight: true),
                    TraceStep("Rete Testis → Efferent Ductules"),
                    TraceStep("Epididymis (sperm maturation + storage; pseudostratified columnar with stereocilia)", highlight: true),
                    TraceStep("Ductus Deferens / Vas Deferens (thick smooth muscle; peristaltic propulsion)", highlight: true),
                    TraceStep("Seminal Vesicles contribute seminal fluid (fructose, prostaglandins)"),
                    TraceStep("Ejaculatory Duct"),
                    TraceStep("Prostate Gland contributes prostatic fluid"),
                    TraceStep("Bulbourethral Glands contribute lubricating mucus"),
                    TraceStep("Urethra → Penis → Preputial Orifice / External environment", highlight: true),
                ],
                keyPoints: [
                    "Seminiferous tubules lined by specialized stratified germinal epithelium — NOT simple cuboidal",
                    "Epididymis has stereocilia (nonmotile microvilli) — NOT true cilia",
                    "Ductus deferens is one of the most muscular ducts in the body (powerful peristalsis)",
                    "Accessory glands add fluid: seminal vesicles → prostate → bulbourethral glands",
                    "Preputial orifice is the external male opening near umbilical cord (sex ID landmark)",
                ],
                highYield: true
            ),
            TraceQuestion(
                title: "CO₂: Fetal Thigh Muscle → Outside Mother's Nose",
                scenario: "Trace a molecule of CO₂ from a cell in the muscle of a fetal pig's left thigh (Left Biceps femoris) all the way to the air outside its mother's nose. This trace crosses the fetal circulatory system, the epitheliochorial placenta, enters the maternal bloodstream, travels through the maternal heart, reaches the maternal lungs, and exits through the mother's nose.",
                category: "Fetal Circulation",
                steps: [
                    TraceStep("CO₂ produced in cell of Left Biceps femoris (left thigh muscle)", highlight: true),
                    TraceStep("Diffuses into Left Deep Femoral Capillaries"),
                    TraceStep("Left Deep Femoral Venules"),
                    TraceStep("Left Deep Femoral Vein"),
                    TraceStep("Left External Iliac Vein"),
                    TraceStep("Left Common Iliac Vein"),
                    TraceStep("Caudal Vena Cava (fetal)", highlight: true),
                    TraceStep("Right Atrium (fetal)", highlight: true),
                    TraceStep("Foramen Ovale — Fetal Shunt #2: right-to-left atrial bypass, skipping nonfunctional fetal lungs", highlight: true),
                    TraceStep("Left Atrium (fetal)"),
                    TraceStep("Bicuspid (Mitral) Valve"),
                    TraceStep("Left Ventricle (fetal)"),
                    TraceStep("Aortic Semilunar Valve"),
                    TraceStep("Ascending Aorta (fetal)"),
                    TraceStep("Arch of the Aorta (fetal)"),
                    TraceStep("Descending (Dorsal) Aorta (fetal)", highlight: true),
                    TraceStep("Left Internal Iliac Artery"),
                    TraceStep("Left Umbilical Artery — carries CO₂-laden blood AWAY from fetus toward placenta (arterial despite being deoxygenated)", highlight: true),
                    TraceStep("Left Umbilical Arteriole"),
                    TraceStep("Fetal Placental Capillaries (within chorioallantoic membrane)", highlight: true),
                    TraceStep("CO₂ diffuses across 6-layer epitheliochorial barrier: fetal capillary endothelium → fetal connective tissue → chorionic trophoblast epithelium → uterine epithelium → maternal connective tissue → maternal capillary endothelium", highlight: true),
                    TraceStep("Maternal Uterine Capillaries — CO₂ now in maternal bloodstream", highlight: true),
                    TraceStep("Right Uterine Venules"),
                    TraceStep("Right Uterine Vein"),
                    TraceStep("Right Internal Iliac Vein"),
                    TraceStep("Right Common Iliac Vein"),
                    TraceStep("Caudal Vena Cava (maternal)", highlight: true),
                    TraceStep("Right Atrium (maternal)", highlight: true),
                    TraceStep("Tricuspid Valve (maternal) — mother's foramen ovale is closed; blood goes to right ventricle"),
                    TraceStep("Right Ventricle (maternal)"),
                    TraceStep("Pulmonary Semilunar Valve"),
                    TraceStep("Pulmonary Trunk (maternal)", highlight: true),
                    TraceStep("Right Pulmonary Artery"),
                    TraceStep("Right Pulmonary Arterioles"),
                    TraceStep("Right Pulmonary Capillaries", highlight: true),
                    TraceStep("CO₂ diffuses through Maternal Pulmonary Capillary Endothelium", highlight: true),
                    TraceStep("Diffuses through Alveolar Epithelium (Type I pneumocytes — simple squamous)"),
                    TraceStep("Alveoli", highlight: true),
                    TraceStep("Alveolar Sacs"),
                    TraceStep("Right Bronchioles"),
                    TraceStep("Right Primary Bronchus"),
                    TraceStep("Trachea (maternal)", highlight: true),
                    TraceStep("Larynx"),
                    TraceStep("Glottis"),
                    TraceStep("Laryngeal Pharynx"),
                    TraceStep("Nasal Pharynx"),
                    TraceStep("Right Internal Nostril (Choana)"),
                    TraceStep("Right Nasal Cavity"),
                    TraceStep("Right External Nostril", highlight: true),
                    TraceStep("Air outside mother's nose — CO₂ released to environment ✓", highlight: true),
                ],
                keyPoints: [
                    "This trace crosses TWO circulatory systems (fetal + maternal) that never directly mix",
                    "Foramen ovale shunts blood right atrium → left atrium in the fetus, bypassing the nonfunctional fetal lungs — this is why CO₂ from the legs bypasses the fetal pulmonary circuit entirely",
                    "Umbilical ARTERIES carry deoxygenated/CO₂-laden blood AWAY from the fetus to the placenta — opposite of the normal arterial convention",
                    "Pig placenta is epitheliochorial (6 layers) — fetal and maternal blood never mix; CO₂ diffuses passively across all 6 layers down its concentration gradient",
                    "Once in maternal blood, CO₂ reaches the maternal RIGHT heart via caudal vena cava → tricuspid valve (not foramen ovale, which is closed in adults)",
                    "Final path: maternal right heart → pulmonary trunk → pulmonary capillaries → diffuse into alveoli → up the airway → out the nostril",
                    "Total systems crossed: fetal venous → fetal heart (foramen ovale) → fetal arterial → placental barrier → maternal venous → maternal heart (tricuspid) → maternal pulmonary → maternal airway",
                ],
                highYield: true
            ),
        ]
    }

    // MARK: - Fill-in-the-Blank Data

    private func createFillBlanks() -> [FillBlankQuestion] {
        return [
            FillBlankQuestion(
                prompt: "Surrounding the lungs are the ___ membranes, which consist of the ___ that covers the lungs and the ___ that lines the thoracic cavity.",
                answers: ["pleural", "visceral pleura", "parietal pleura"],
                explanation: "The pleural membranes form a closed sac around each lung. The visceral pleura adheres to the lung surface; the parietal pleura lines the thoracic wall. The pleural cavity between them contains serous fluid.",
                category: "Respiratory"
            ),
            FillBlankQuestion(
                prompt: "The ___ is the site that connects the lungs to the mediastinum and contains vital structures such as the main bronchi, pulmonary arteries, and pulmonary veins.",
                answers: ["hilum"],
                explanation: "The hilum (root of the lung) is the medial indentation where bronchi, pulmonary vessels, lymphatics, and nerves enter/exit each lung.",
                category: "Respiratory"
            ),
            FillBlankQuestion(
                prompt: "The trachea is lined by ___ epithelium, which contains ___ cells that move mucus and ___ cells that secrete mucus.",
                answers: ["pseudostratified ciliated columnar", "ciliated", "goblet"],
                explanation: "The mucociliary escalator: goblet cells secrete mucus that traps particles; ciliated cells beat rhythmically to sweep mucus toward the pharynx.",
                category: "Histology"
            ),
            FillBlankQuestion(
                prompt: "The esophagus is lined by ___ epithelium, which contrasts with the ___ epithelium of the trachea immediately adjacent to it.",
                answers: ["stratified squamous nonkeratinized", "pseudostratified ciliated columnar"],
                explanation: "This contrast is extremely high yield: same region of the body, completely different epithelial types. The esophagus needs protection from abrasion; the trachea needs mucociliary clearance.",
                category: "Histology"
            ),
            FillBlankQuestion(
                prompt: "The three fetal circulatory shunts are the ___, which bypasses the liver; the ___, which bypasses the right ventricle and pulmonary circuit; and the ___, which bypasses the lungs.",
                answers: ["ductus venosus", "foramen ovale", "ductus arteriosus"],
                explanation: "All three shunts allow fetal blood to bypass the nonfunctional lungs. They close at birth and become the ligamentum venosum, fossa ovalis, and ligamentum arteriosum respectively.",
                category: "Fetal Circulation"
            ),
            FillBlankQuestion(
                prompt: "The ___ valve separates the right atrium from the right ventricle, while the ___ (or ___) valve separates the left atrium from the left ventricle.",
                answers: ["tricuspid", "bicuspid", "mitral"],
                explanation: "Mnemonic: 'Try before you buy' — Tricuspid before Bicuspid in the direction of blood flow. Right side always before left side in the pulmonary → systemic circuit.",
                category: "Circulatory"
            ),
            FillBlankQuestion(
                prompt: "The ___ is the most commonly forgotten vessel in the maternal-to-fetal circulatory trace. It branches from the descending aorta and gives rise to the ___ artery supplying the uterus.",
                answers: ["internal iliac artery", "uterine"],
                explanation: "The complete maternal path: descending aorta → internal iliac artery → uterine artery → uterine arterioles → maternal placental capillaries → chorioallantoic membrane.",
                category: "Fetal Circulation"
            ),
            FillBlankQuestion(
                prompt: "Pigs have a ___ iliac vein but NO ___ iliac artery — the arterial side divides directly into internal and external iliac arteries.",
                answers: ["common", "common"],
                explanation: "This pig-specific anatomical feature distinguishes pigs from many other mammals. The common iliac vein collects from both internal and external iliac veins; on the arterial side, the aorta branches directly to internal and external iliac arteries.",
                category: "Circulatory"
            ),
            FillBlankQuestion(
                prompt: "The ___ are scroll-like structures inside the nasal cavity that increase surface area, warm inspired air, humidify air, and trap particles.",
                answers: ["conchae (turbinates)"],
                explanation: "The conchae (nasal turbinates) are extremely high yield for the practical. They are lined by pseudostratified ciliated columnar epithelium and perform critical air conditioning functions.",
                category: "Respiratory"
            ),
            FillBlankQuestion(
                prompt: "The urinary bladder is lined by ___ epithelium, also called ___. This type can ___ as the bladder fills.",
                answers: ["transitional", "urothelium", "stretch"],
                explanation: "Transitional epithelium (urothelium) is unique to the urinary tract. Dome-shaped 'umbrella cells' on the surface flatten when the bladder distends, allowing massive volume changes.",
                category: "Histology"
            ),
            FillBlankQuestion(
                prompt: "Seminiferous tubules are lined by specialized ___ epithelium. ___ cells between the tubules secrete testosterone, while ___ cells inside the tubules support sperm maturation.",
                answers: ["stratified germinal", "Leydig", "Sertoli"],
                explanation: "High yield histology: seminiferous tubule epithelium is a specialized stratified germinal epithelium (not simple cuboidal). Leydig cells are interstitial (between tubules); Sertoli cells are inside the tubules.",
                category: "Reproductive"
            ),
            FillBlankQuestion(
                prompt: "The glottis is the ___ leading into the larynx, while the ___ is the cartilaginous flap that covers it during swallowing.",
                answers: ["opening", "epiglottis"],
                explanation: "Glottis = opening (not a structure per se). Epiglottis = flap. This distinction was specifically noted as a common confusion point.",
                category: "Respiratory"
            ),
        ]
    }
}
