module Annales.Descriptions (
  descSuccession
  , descAcclamation
  , descWar
  , descBattle
  , descWinWar
  , descWedding
  , descBirth
  , descDeathOf
  , descTribe
  , descTribeGo
  , descTribeActivity
  , descCourtier
  , descCourtDouble
  , descCourtierGo
  , descBuildingName
  , descNewBuilding
  , descModifyBuilding
  , descBuildingGone
  , descOmen
  ) where
  
import Annales.Empire (
  TextGenCh
  ,Empire
  ,Person(..)
  ,Gender(..)
  ,claimants
  ,emperor
  ,court
  ,buildings
  ,tribes
  ,generate
  ,vocabGet
  ,pName
  ,pGender
  ,dumbjoin
  ,wordjoin
  ,nicelist
  ,inc
  ,paragraph
  ,sentence
  ,cap
  ,capg
  ,cap1g
  ,randn
  ,randRemove
  ,chooseW
  ,phrase
  ,possessive
  )

import TextGen (
  TextGen
  ,word
  ,choose
  ,weighted
  ,remove
  ,perhaps
  ,list
  ,aan
  )


w :: [ Char ] -> TextGenCh
w = word

ch :: [ TextGenCh ] -> TextGenCh
ch = choose

chw :: [[ Char ]] -> TextGenCh
chw = chooseW
--
--
-- Successions, wars and battles
--
--

descSuccession :: TextGenCh -> TextGenCh
descSuccession style = inc [ w "Succession of", style ]

-- add: war of N things

descWar :: Empire -> TextGenCh
descWar e = let v = vocabGet e
                name = ch [ woq, adjw ]
                woq = list [ w "War of", capg $ v "abstractions" ]
                adjw = list [ capg $ v "adjectives", w "War" ]
                forces = nicelist $ map pName $ claimants e
                met = chw [ "were joined", "battled", "clashed", "disagreed", "contended", "disputed", "sought mastery" ]
                began = chw [ "Now began the", "In this year was begun the", "Beginning of the" ]
                s1 = inc [ forces, met, w "in the", name ]
                s2 = inc [ began, name, w ",", w "in which", forces, met ]
            in ch [ s1, s2 ]

descAcclamation :: Empire -> TextGenCh -> TextGenCh
descAcclamation e style = inc [ style, vocabGet e "enthroned", how ]
  where how = weighted [
          ( 90, vocabGet e "acclamations_sensible" )
          ,( 10,  vocabGet e "acclamations_silly" )
          ]


-- these two are not wrapped in inc because they will be returned as separate
-- paragraphs.



descBattle :: Empire -> Person -> Person -> Maybe Person -> [ TextGenCh ]
descBattle e a b mv = let d = case mv of
                            Nothing -> False
                            Just _  -> True
                          battle = ch [ ambush e a b, siege e a b d, pitched e a b ]
                      in case d of
                           True -> [ battle, battleLoss e b ]
                           False ->  [ battle ]


  
-- generators used in all the battles

forces = list [ w "the", chw [ "legions", "armies", "forces", "warriors", "soldiers", "men" ] ]

allies :: Empire -> TextGenCh
allies e = phrase $ list [ aided, bywho ]
  where v = vocabGet e
        aided = chw [ "with the aid of", "in league with", "allied with", "calling on" ]
        bywho = choose [ list [ certain, v "adjectives", v "allies" ], dingus ]
        certain = perhaps ( 1, 3 ) $ chw [ "certain", "some" ]
        dingus = list [ w "the", v "artifacts" ]
                  

battleLoss :: Empire -> Person -> TextGenCh
battleLoss e d = sentence $ choose [ battleDeath e n ] --, disgrace n ]
  where n = pName d



battleDeath :: Empire -> TextGenCh -> TextGenCh
battleDeath e d = weighted [
  (30,   resting )
  ,( 40, byWeapon )
  ,( 20, honour ),
   ( 10, ghost )
  ]
  where resting = list [
          chw [ "Now the", "They tell that the", "Certain it is that the" ]
          , choose [
              list [ chw [ "bones", "parts", "ouns" ], w "of", d, chw [ "leave not", "remain in", "rest in" ] ],
              list [ chw [ "body", "clay", "dust" ], w "of", d, chw [ "leaves not", "remains in", "rests in" ] ]
              ]
          ,chw [ "those fields", "that place", "the cold earth" ]
          ]
        remains = chw [ ]
        honour = list [
          w "Of", d, chw [ "there is no more that", "little more", "no futher tales" ]
          , w "can be told, save the"
          , chw [ "songs", "wailing", "cries" ], w "of",
            chw [ "honour", "shame", "sorrow", "glory" ]
          ]
        byWeapon = list [
          cap1g $ aan $ list [
              perhaps (1, 3) $ chw [ "thirsty", "avid", "hungry", "bitter" ]
              ,vocabGet e "weapons"
              ]
          , w "was the", chw [ "bane", "end", "last bedmate" ], w "of"
          , perhaps ( 1, 2 ) $ chw [ "noble", "brave", "honoured" ]
          , d
          ]
        ghost = list [
          chw [ "Now the", "The", "They say that the" ]
          , chw [ "spirit", "shade", "ghost", "voice" ]
          , w "of", d
          , chw [
              "may yet be heard in"
              ,"echoes in"
              ,"haunts"
              ,"yet lingers in"
              ,"remains in"
              ]
          , chw [ "that place", "those fields" ]
          ]
          
  



-- types of battles

ambush :: Empire -> Person -> Person  -> TextGenCh
ambush e a b = sentence $ list [ pName a, perhaps ( 1, 3 ) $ allies e, ambushed ]
  where ambushed = ch [
          list [ chw [ "ambushed the", "surprised the"], forces, w "of", pName b ], 
          list [ w "took", forces, w "of", pName b, w "all unawares" ]
          ]


siege :: Empire -> Person -> Person -> Bool -> TextGenCh
siege e a b d = choose [ siege' e a b d, siege' e b a d ]

siege' :: Empire -> Person -> Person -> Bool -> TextGenCh
siege' e a b dec = list [ cap1g $ sentence $ sdesc, w " ", cap1g $ sentence $ end ]
  where besiegers = list [ forces, w "of", pName a ]
        besieged = list [ forces, w "of", pName b ]
        place = list [ w "in", perhaps (1, 2) citadel, vocabGet e "places" ]
        citadel = list [ w "the", chw [ "fortress", "redoubt", "castle", "villa", "dairy", "temple" ], w "of" ]
        until = list [ w "until", choose [ s1, s2, s3 ] ]
        s1 = list [ w "they were reduced to drinking", vocabGet e "drinks" ]
        s2 = list [ w "they had only", vocabGet e "foods", w "for provender" ]
        s3 = list [ vocabGet e "diseases", w "stalked the", chw [ "streets", "parapets", "walls" ] ]
        sdesc = list [ besiegers, chw [ "laid siege to", "embattled", "besieged", "trapped" ], besieged, place, until ]
        time = chw [ "Finally", "At last", "After many months" ]
        end = case dec of
          True -> list [ time, phrase $ chw [ "their walls were thrown down", "the gates were breached", "fire and blood were their end" ] ]
          False -> list [ time, allies e, w "the siege was broken" ]

pitched :: Empire -> Person -> Person -> TextGenCh
pitched e a b = list [ sentence $ cap1g $ armies, w " ", sentence $ cap1g $ outcome ]
  where forcea = list [ forces, w "of", pName a ]
        forceb = list [ forces, w "of", pName b ]
        ground = chw [ "Fields", "Meads", "Plain", "Meadows", "Flats", "Marshes", "Fens", "Bogs" ]
        battleground = list [ ground, w "of", vocabGet e "places" ]
        armies = list [ forcea, w "and", forceb, w "met on the", battleground ]
        outcome = list [ number, warriors, died ]
        number = chw [ "Countless", "Numberless", "Thousands of", "Hundreds of", "Dozens of", "A good many" ]
        warriors = chw [ "warriors", "fighting men", "men", "heroes", "soldiers" ]
        died = chw [ "died", "sought a cold bed", "bedewed the grass", "met their end", "died in harness" ]








descWinWar :: Empire -> TextGenCh -> TextGenCh
descWinWar e style = list [ style, vocabGet e "enthroned", w "triumph" ]

--
--
--  Marriages and births
--
--

descWedding :: Empire -> TextGenCh -> TextGenCh
descWedding e cg = let me = emperor e
                       eg = case me of
                         Just emp -> pName emp
                         Nothing -> word "ERROR"
                       v = vocabGet e
                       waswed = chw [ "was wedded to", "espoused", "married", "was joined with" ]
                       celebrated = list [ w "with", much, v "festivities" ]
                       much = chw [ "great", "loud", "much", "wild", "joyful", "happy" ]
                   in inc [ eg, waswed, cg, celebrated ]


descBirth e mother baby = let (Person pg _ g) = baby
                              (Person mg _ _) = mother
                              v = vocabGet e
                              child = if g == Male then w "son" else w "daughter"
                          in inc [ mg, birth, child, phrase pg, birthCircs e ]

birth = chw [ "was brought to bed of a", "gave birth to a", "was blessed with a", "bore a", "was accouched of a" ]

birthCircs e = perhaps ( 2, 7 ) $ choose [ birthStar e, birthBastard e, birthOmen e ]

birthStar e = choose [ inf, rising, setting, pmoon ]
  where s = vocabGet e "stars"
        inf = list [ w "under the influence of", s ]
        rising = list [ w "at the heliacal rising of", s ]
        setting = list [ w "at the setting of", s ]
        pmoon = list [ chw [ "during", "under" ], mp, w "moon" ]
        mp = chw [ "a full", "a waning", "a gibbous", "the friendly silence of the" ]


birthBastard e = case bastardFathers e of
  [] -> birthStar e
  bfs -> phrase $ list [ said, w "to be", bastard, w "of", choose bfs ]
    where said = chw [ "whispered", "rumoured", "said" ]
          bastard = chw [ "the bastard", "a by-blow", "the image" ]

bastardFathers e = map (\(Person g _ _) -> g) $ males
  where males = filter (\(Person _ _ pg) -> pg == Male ) $ court e


birthOmen e = phrase $ list [
  chw [ "during", "attended by", "in the course of", "in a night of", "in a day of" ]
  ,perhaps ( 1, 2 ) $ chw [ "mighty", "great", "fearsome", "glorious" ]
  ,vocabGet e "phenomena"
  ]



--
--
-- Deaths (other than in battle)
--
--


descDeathOf :: Empire -> Person -> TextGenCh
descDeathOf e p = inc [ pName p, death e p ]

death :: Empire -> Person -> TextGenCh
death e p = weighted [
  ( 5, choke e),
  (4, beast e),
  (41, disease e),
  (30, assassination e p),
  (10, poison e),
  (10, witchcraft e)
  ]


choke e = list [ w "choked on", aan $ ch [ bone, other ] ]
  where bone = list [ vocabGet e "monsters", chw [ "bone", "shell"]  ]
        other = vocabGet e "foods"

beast e = list [ verbedby, aan $ vocabGet e "monsters" ]
  where verbedby = chw [
          "was stung by"
          ,"was bitten by"
          ,"was allergic to"
          ,"swallowed"
          ,"was eaten by"
          ]


disease e = list [ chw [ "succumbed to", "died of", "was taken by" ], vocabGet e "diseases" ]

poison e = choose [ chaumas e, chaumurky e, chausmetics e ]

chaumas e = list [ w "ate", bad, vocabGet e "foods" ]
  where bad = chw [ "poisoned", "rotten", "bad", "spoiled", "tainted" ]

chaumurky e = list [ w "drank", bad, vocabGet e "drinks" ]
  where bad = chw [ "poisoned", "new", "sour", "tainted" ]

chausmetics e = list [ w "was poisoned with", vocabGet e "cosmetics" ]

witchcraft e = chw [ "was ensorcelled", "was beguiled", "was spellbound", "succumbed to a geas" ] 

assassination e p = list [ w "was", deathmode, location ]
  where deathmode = choose [
          list [
              chw [ "stabbed", "slashed", "murdered", "slain", "gutted" ]
              , perhaps ( 1, 2) $ list [ w "with", aan $ vocabGet e "weapons" ]
              ]
          ,chw [ "drowned", "throttled", "smothered", "strangled", "crushed" ]
          ]
        location = list [
          chw [ "in", "before", "behind" ]
          ,choose [
              list [ w "the", randBuilding e]
              , list [ poss, chamber ]
              ]
          ]
        poss = possessive p
        chamber = chw [
          "bedchamber", "privy", "parlour", "dressing-room", "pavillion"
          ]


--
--
-- Courtiers
--
--

-- things courtiers can do: write poems and plays and histories,
-- intrigue, win triumphs, be exiled to PLACE, retire to their
-- villa/etc in PLACE, sponsor games, projects


-- descCourtier :: Empire -> Person -> TextGenCh
-- descCourtier e p = inc [ pName p, w "rocked up" ]


descCourtier :: Empire -> Person -> TextGenCh
descCourtier e p = inc [
  choose [
      list [ arrived e p, w "after having", achievement e ],
      list [ w "Having", achievement e, w ",", arrived e p ]
      ,list [
          chw [ "Now", "In this year", "At this time", "In this season" ]
          , arrived e p
          ]
      ]
  ]

achievement :: Empire -> TextGenCh
achievement e = choose [
  descCourtTribe e
  ,list [ chw [ "written", "penned", "distributed" ],
         perhaps ( 1, 2 ) $ chw [ "certain", "some" ],
         descLiterature e
       ]
  ,wonFavour e
  ]


wonFavour :: Empire -> TextGenCh
wonFavour e = list [ favour, who ]
  where favour = chw [
          "caught the eye of"
          ,"won the favour of"
          ,"flattered"
          ,"impressed"
          ,"performed certain offices for"
          ,"earned the esteem of"
          ,"earned the gratitude of"
          ]
        who = case court e of
                [] -> list [ w "a noble", chw [ "lady", "lord" ] ]
                cs -> chooseP cs
  

arrived :: Empire -> Person -> TextGenCh
arrived e p = list [ pName p, desc, cametocourt ]
  where wman = if pGender p == Male then w "man" else w "woman"
        v = vocabGet e
        desc = phrase $ weighted [ (40, noble), (10, humble), (50, personal), (10, ofatribe) ]        
        noble = list [
          w "a noble of", perhaps ( 1, 2 ) $ w "the house of", v "places"
          ]
        humble = list [
          w "a", wman, w "of", chw [ "low birth", "humble birth", "no name", "no pedigree", "no estate" ]
          ,perhaps (1, 2) $ phrase $list [
              w "whose"
              ,chw [ "father", "mother" ]
              ,chw [ "dealt in", "traded in", "sold" ]
              ,choose [ v "foods", v "drinks" ]
              ]
          ]
        personal = list [
          aan $ v "adjectives", wman, w ","
          ,chw [ "adept at", "mighty at", "great with", "skilled in" ]
          ,choose [ skills, weapons ]
          ]
        ofatribe = list [
          w "said to be"
          , chw [ "of the", "of the blood of the", "one of the" ]
          , currentTribe e
          ]
        skills = chw [
          "intrigue"
          ,"warfare"
          , "courtship"
          , "wizardry"
          , "learning"
          , "the chase"
          , "the arts of love"
          , "letters"
          , "politics"
          ]
        weapons = list [ wskill, v "weapons" ]
        wskill = chw [ "the", "the arts of the", "the use of the", "wielding the", "the skills of the" ]
        cametocourt = chw [
          "rose to prominence",
          "arrived at court",
          "was much spoken of",
          "was promoted",
          "became known",
          "was in the eye of fortune",
          "was the talk of the court"
          ]







descCourtTribe :: Empire -> TextGenCh
descCourtTribe e = list [ defeated, w "the", currentTribe e ]
  where defeated = chw [
          "defeated", "exterminated", "punished", "quelled"
          , "triumphed over", "repressed", "embarrassed", "harassed"
          , "controlled", "bested"
          ]








descCourtDouble :: Empire -> Person -> TextGenCh
descCourtDouble e p = inc [ w "Fearful omen of a doppleganger of", pName p, w "at court" ]


descCourtierGo :: Empire -> Person -> [ Person ] -> TextGenCh
descCourtierGo e p c = inc $ [ choose [ s1, s2, s3, s4 ] ]
  where s1 = list [ cap1g $ crime, w ",", name, waspunished ]
        s2 = list [ name, phrase $ crime, waspunished ]
        s3 = list [ name, waspunished, w "for", crime ]
        s4 = retirement e p
        crime = misdeed e p c
        name = pName p
        waspunished = punishment e

retirement :: Empire -> Person -> TextGenCh
retirement e p = choose [
  list [ pName p, retired, w ",", wearying ]
  ,list [ cap1g $ wearying, w ",", pName p, retired ]
  ]
  where poss = possessive p
        retired = list [
          choose [
              w "retired to"
              , w "retreated to"
              , w "left for"
              , list [ w "spent", poss, chw [ "remaining", "last" ], chw [ "days", "years" ], w "at" ]
              ]
          , poss
          , chw [ "villa", "palace", "estates", "home", "cave", "fortress" ]
          , w "in", vocabGet e "places"
          ]
        wearying = list [
          chw [
              "wearying of", "tiring of", "disgusted with", "having grown weary of",
              "satiated with", "replete with", "spurning", "having exhausted",
              "leaving", "abandoning", "forsaking"
              ]
          ,w "the"
          ,perhaps ( 2, 3 ) $ vocabGet e "adjectives"
          ,choose [ vocabGet e "abstractions", vocabGet e "festivities" ]
          ,w "of the"
          ,chw [ "court", "throne", "palace", "capital", "salon", "city" ]
          ]

          

misdeed :: Empire -> Person -> [ Person ] -> TextGenCh
misdeed e p c = case maybeAffair e p c of
  (Just affair) -> weighted [
    ( 20, writing e),
    ( 70, affair ),
    ( 60, traitor e),
    ( 20, blasphemy e)
    ] 
  Nothing       -> weighted [
    ( 20, writing e),
    ( 60, traitor e),
    ( 20, blasphemy e)
    ]


punishment :: Empire -> TextGenCh
punishment e = choose [ exiled, maimed, executed, shunned ]
  where exiled = list [ w "was", chw [ "exiled", "banished" ], w "to", vocabGet e "places" ]
        maimed = list [ w "was", corporal e $ chw [
          "maimed", "blinded", "crippled", "killed", "impaled"
          ] ]
        executed = list [ w "was", choose [
          list [ chw [ "cast", "thrown" ], w "from the", randBuilding e ],
          corporal e $ chw [ "beheaded", "sacrificed", "flayed" ],
          list [
              chw [ "drowned", "throttled", "smothered" ]
              ,chw [ "in the", "before the", "behind the" ]
              ,randBuilding e
              ]
          ] ]
        shunned = chw [
          "became unfashionable"
          ,"was excluded from the court"
          ,"dared not appear in company"
          ,"fell under the shadow of infamy"
          ,"wasted away"
          ,"was placed under a geas"
          ]

corporal :: Empire -> TextGenCh -> TextGenCh
corporal e what = list [
              what
              ,w "with", aan $ vocabGet e "weapons"
              ,perhaps ( 1, 3 ) $ list [
                  chw [ "in the", "before the", "behind the" ]
                  ,randBuilding e
              ]
              ]

          
writing e = list [
  chw [
      "having penned",
      "having circulated",
      "having repeated",
      "having written",
      "composing",
      "writing",
      "reciting",
      "being credited with"
      ]
  , perhaps (2, 3) $ chw [ "certain", "some" ]
  , descLiterature e
  ]


descLiterature e = list [ v "litadj", v "literature" ]
  where v = vocabGet e



maybeAffair :: Empire -> Person -> [ Person ] -> Maybe TextGenCh
maybeAffair e p c = case filter ( \(Person _ a _) -> a > 16 ) c of
                  [] -> Nothing
                  ps -> Just $ affairWith e p $ chooseP ps 


affairWith :: Empire -> Person -> TextGenCh -> TextGenCh
affairWith e p pg = choose [
    list [
        chw [
            "having flaunted"
            ,"flaunting"
            ,"barely concealing"
            ,"bragging of"
            ,"being unashamed of"
            ,"brazenly enjoying"
            ,"having exaggerated"
            ,"spreading rumours of"
            ]
        ,possessive p ,vocabGet e "abstractions", w "with"
        ,pg
        ]
    ,list [
        chw [
            "comitting"
            ,"having committed"
            ,"having been discovered in"
            ]
        ,vocabGet e "abstractions", w "with"
        ,pg
        ]
    ,list [
        chw [
            "growing"
            ,"becoming"
            ,"having become"
            ,"having grown"
            ]
        ,vocabGet e "adjectives", w "of"
        ,pg
        ]
  ]


traitor e = list [
  chw [
      "conspiring with"
      ,"consorting with"
      ,"aiding"
      ,"abetting"
      ,"recieving messages from"
      ,"sympathising with"
      ,"having been compromised by"
      ,"having relations with"
      ]
  ,w "the"
  ,currentTribe e
  ]

blasphemy e = list [ choose [ b1, b2, b3 ], ptg, vocabGet e "gods" ]
  where b1 = list [
          w "failing to"
          , chw [ "honour", "reverence", "worship", "acknowledge" ]
          ]
        b2 = list [
          chw [ "speaking", "having spoken" ]
          , chw [ "lightly", "brazenly", "openly" ]
          , w "of"
          ]
        b3 = list [
          perhaps (1, 2) $ chw [ "secretly", "indiscreetly" ]
          , chw [ "honouring", "worshipping", "blaspheming" ]
          ]
        ptg = perhaps ( 1, 3 ) $ chw [ "the god", "the goddess" ]


--
--
-- Tribes
--
--

currentTribe :: Empire -> TextGenCh
currentTribe e = case tribes e of
                   [] -> vocabGet e "tribes" 
                   ts -> choose ts


descTribe :: Empire -> TextGenCh -> TextGenCh
descTribe e t = let v = vocabGet e
                    nation = phrase $ aan $ list [ v "adjectives", v "nations" ]
                    givento = list [ v "proneto", v "abstractions" ]
                    worship = list [ v "worshipping", perhaps (1, 2) $ v "divine", v "gods" ]
                    clause = perhaps (2, 3) $ phrase $ ch [ givento, worship ]
                    arose = list [ w "arose in", v "places" ]
                in inc [ w "The", t, nation, clause, arose ]

descTribeGo :: Empire -> TextGenCh -> TextGenCh
descTribeGo e tribe = inc [ w "The", tribe, went ]
  where v = vocabGet e
        went = ch [ dwindled, conquered, migrated, fled, monster ]
        dwindled = chw [ "dwindled", "dissolved", "failed" ]
        conquered = list [ w "were conquered by the", vocabGet e "tribes" ]
        migrated = list [ w "migrated to the", chw [ "north", "west", "east", "south" ] ]
        fled = list [ cursed, vocabGet e "phenomena" ]
        cursed = chw [ "were cursed with", "fled the", "fled in the face of" ]
        monster = list [ w "were destroyed by", aan $ v "monsters" ]


descTribeActivity :: Empire -> TextGenCh -> TextGenCh
descTribeActivity e tribe = inc [ w "The", tribe, didstuff ]
  where didstuff = choose [ incursion, destruction, conversion ]
        v = vocabGet e
        incursion = list [
          chw [
              "made incursions in"
              ,"caused trouble in"
              ,"plundered"
              ,"raided"
              ]
          ,v "places"
          ]
        destruction = list [
          chw [ "sacked", "destroyed", "burnt", "overran" ]
          ,v "places"
          ]
        conversion = list [
          chw [ "were converted to", "converted to", "became followers of" ]
          ,v "religions"
          ]
            


--
--
-- Omens
--
--



descOmen :: Empire -> TextGenCh
descOmen e = inc [ collective, phenom, w "in", place ]
  where phenom = vocabGet e "phenomena"
        place = vocabGet e "places"


collective :: TextGenCh
collective = chw [ "Outbreak of", "Panic caused by", "Great", "Reports of", "Rumours of" ]


--
--
-- Buildings
--
--

descBuildingName :: Empire -> TextGenCh
descBuildingName e = ch [ capg $ vocabGet e "buildings", temple e ]

temple e = list [ w "Temple of", vocabGet e "gods" ]

descNewBuilding :: Empire -> TextGenCh -> TextGenCh
descNewBuilding e b = project e b (chw [ "erected", "founded", "established", "built", "constructed" ] )

descModifyBuilding :: Empire -> TextGenCh -> TextGenCh
descModifyBuilding e b = project e b (chw [ "repaired", "renovated", "expanded", "extended", "completed" ] )

project :: Empire -> TextGenCh -> TextGenCh -> TextGenCh
project e building verbed = inc [ person, verbed, w "the", building ]
  where person = choosePerson e


descBuildingGone :: Empire -> TextGenCh -> TextGenCh
descBuildingGone e b = inc [ w "The", b, w "was", destroyed, how ]
  where destroyed = chw [ "destroyed", "ruined", "obliterated", "demolished", "collapsed", "burnt down" ]
        how = list [ w "by", aan $ choose [ vocabGet e "monsters", w "fire", w "flood", w "lightning bolt", w "earthquake", w "riot" ] ]


randBuilding :: Empire -> TextGenCh
randBuilding e = choose ( [ temple e ] ++ buildings e )

choosePerson :: Empire -> TextGenCh
choosePerson e = case emperor e of
                   Nothing -> case court e of
                                [] -> chooseRandPerson e
                                c -> chooseP c
                   (Just emp) -> chooseP (emp:(court e)) 

chooseP :: [ Person ] -> TextGenCh
chooseP [] = word "--"
chooseP ps = choose $ map (\(Person n _ _) -> n) ps

chooseRandPerson :: Empire -> TextGenCh
chooseRandPerson e = choose [ men, women ]
  where men = vocabGet e "men"
        women = vocabGet e "women"


