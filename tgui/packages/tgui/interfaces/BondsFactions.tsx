import { Box, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FactionInfo = {
  name: string;
  accent: string;
};

type StanceEntry = {
  name: string;
  accent: string;
  label: string;
  labelAccent: string;
  intensity: string;
  declared: number | boolean;
};

type HouseEntry = {
  name: string;
  label: string;
  labelAccent: string;
  intensity: string;
  incidents: number;
};

type Data = {
  ownFaction: FactionInfo | null;
  stances: StanceEntry[];
  ownHouse: string | null;
  houses: HouseEntry[];
  ownClan: string | null;
  clans: StanceEntry[];
};

export const BondsFactions = () => {
  const { data } = useBackend<Data>();
  const {
    ownFaction,
    stances = [],
    ownHouse,
    houses = [],
    ownClan,
    clans = [],
  } = data;

  return (
    <Window title="Положение" width={560} height={620}>
      <Window.Content scrollable style={{ backgroundImage: 'none' }}>
        {!ownFaction && !ownHouse && (
          <NoticeBox>Вы не представляете никого, кроме себя.</NoticeBox>
        )}
        <Stack vertical fill>
          {!!ownFaction && (
            <Stack.Item>
              <Section>
                <Box opacity={0.6}>Вы говорите от лица</Box>
                <Box bold fontSize="1.2rem" color={ownFaction.accent}>
                  {ownFaction.name}
                </Box>
              </Section>
            </Stack.Item>
          )}
          {stances.map((stance, index) => (
            <Stack.Item key={`f${index}`}>
              <Section>
                <Box inline bold color={stance.accent}>
                  {stance.name}
                </Box>
                <Box inline ml={1} bold color={stance.labelAccent}>
                  {stance.label}
                </Box>
                <Box opacity={0.6} mt={0.5}>
                  {stance.intensity}
                </Box>
              </Section>
            </Stack.Item>
          ))}
          {!!ownClan && (
            <Stack.Item>
              <Section title={`Клан: ${ownClan}`}>
                <Stack vertical>
                  {clans.map((clan, index) => (
                    <Stack.Item key={`c${index}`}>
                      <Box inline bold color={clan.accent}>
                        {clan.name}
                      </Box>
                      <Box inline ml={1} bold color={clan.labelAccent}>
                        {clan.label}
                      </Box>
                      <Box opacity={0.6}>{clan.intensity}</Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}
          {!!ownHouse && (
            <Stack.Item>
              <Section title={`Дом ${ownHouse}`}>
                {!houses.length && (
                  <Box opacity={0.6}>
                    С другими домами у вас пока ничего не случалось.
                  </Box>
                )}
                <Stack vertical>
                  {houses.map((house, index) => (
                    <Stack.Item key={`h${index}`}>
                      <Box inline bold>
                        {house.name}
                      </Box>
                      <Box inline ml={1} bold color={house.labelAccent}>
                        {house.label}
                      </Box>
                      <Box opacity={0.6}>
                        {house.intensity} · случаев: {house.incidents}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
