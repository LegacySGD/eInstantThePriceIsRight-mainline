<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson">
				<lxslt:script lang="javascript">
					<![CDATA[
					// Limited to 50 strings of Debuging
					var debugFeed = [];
					var debugFlag = false;
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, convertedPrizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						//var gameData = scenario.split('|');
						//var dataGame1 = gameData.slice(0,2);
						//var dataGame2 = gameData.slice(2,4);
						//var dataGame2A = dataGame2[0].split(':');
						//var dataGame2B = dataGame2[1].split(':');
						//var dataGame2AWin = dataGame2A[0];
						//var dataGame2BWin = dataGame2B[0];
						//var dataGame2ATurns = dataGame2A[1].split(',');
						//var dataGame2BTurns = dataGame2B[1].split(',');

						// split scenario text "aaa|bbb|I:cII,dIII,eIV|V:fVI,gVII,hVIII|ttttttttttt:M|L:i,j,k,l,m|n" into the object:
						//
						// {game11 : "aaa";
						//  game12 : "bbb"
						//  game21 : object {winNum: "I"; turns: array [object {prize: "c"; yourNum: "II"}, object {prize: "d"; yourNum: "III"}, object {prize: "e"; yourNum: "IV"}]}
						//  game22 : object {winNum: "V"; turns: array [object {prize: "f"; yourNum: "VI"}, object {prize: "g"; yourNum: "VII"}, object {prize: "h"; yourNum: "VIII"}]}
						//  bonus  : object {tokens: "ttttttttttt"; multi: "M"}
						//  game3  : object {layout: "L"; turns: array ["i","j","k","l","m"]}
						//  multi  : "n"}

						var objKeys = "game11,game12,game21,game22,bonus,game3,multi".split(",");
						var gameData = {};
						scenario.replace(/[^|]+/g, function(match){gameData[objKeys.shift()] = match});

						var dataTemp = "";
						for (gamePart=1; gamePart<=2; gamePart++)
						{
							objKeys = "winNum,turns".split(",");
							dataTemp = gameData["game2"+gamePart];
							gameData["game2"+gamePart] = {};
							dataTemp.replace(/[^:]+/g, function(match){gameData["game2"+gamePart][objKeys.shift()] = match});

							gameData["game2"+gamePart].turns = gameData["game2"+gamePart].turns.split(",");
    
							for (turnPart=0; turnPart<=2; turnPart++)
							{
								objKeys = "prize,yourNum".split(",");
								dataTemp = gameData["game2"+gamePart].turns[turnPart];
								gameData["game2"+gamePart].turns[turnPart] = {};
								dataTemp.replace(/\D/, function(match){gameData["game2"+gamePart].turns[turnPart][objKeys.shift()] = match});
								dataTemp.replace(/\d+/, function(match){gameData["game2"+gamePart].turns[turnPart][objKeys.shift()] = match});
							}
						}

						objKeys = "tokens,multi".split(",");
						dataTemp = gameData.bonus;
						gameData.bonus = {};
						dataTemp.replace(/[^:]+/g, function(match){gameData.bonus[objKeys.shift()] = match});

						objKeys = "layout,turns".split(",");
						dataTemp = gameData.game3;
						gameData.game3 = {};
						dataTemp.replace(/[^:]+/g, function(match){gameData.game3[objKeys.shift()] = match});

						gameData.game3.turns = gameData.game3.turns.split(",");

						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var prizeValues = (convertedPrizeValues.substring(1)).split('|');
						
						//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			
						// Print Translation Table to !DEBUG
						var index = 1;
						registerDebugText("Translation Table");
						while(index < translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}
						
						// !DEBUG
						//registerDebugText("Translating the text \"softwareId\" to \"" + getTranslationByName("softwareId", translations) + "\"");
						///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					
						// Output winning numbers table.
						var r = [];
						var showWin = false;
						var prizeText = '';
						var prizesData = '';

						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');

						for (gamePart=1; gamePart<=2; gamePart++)
						{
							prizeText = gameData["game1"+gamePart][0];
							showWin = (gameData["game1"+gamePart] == 'xxx'.replace(/x/g, prizeText));
							prizesData = '';

							r.push('<tr>');
								r.push('<td class="tablebody">');
									r.push(getTranslationByName("gameNum", translations) + ' 1 ' + getTranslationByName("gameRow", translations) + ' ' + gamePart + ':');
								r.push('</td>');
								r.push('<td class="tablebody">');
									r.push(getTranslationByName("gamePrizes", translations) + ': ');
								r.push('</td>');
								r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
									for (prizesIndex=0; prizesIndex<3; prizesIndex++)
									{
										prizeText = gameData["game1"+gamePart][prizesIndex];
										prizesData += ((prizesData != '') ? ', ' : '') + prizeValues[prizeNames.indexOf(prizeText)];
									}

									r.push(prizesData);
								r.push('</td>');
								r.push('<td class="tablebody">');
									r.push('&nbsp;');
								r.push('</td>');
								r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
									r.push((showWin) ? getTranslationByName("win", translations) + ' ' + prizeValues[prizeNames.indexOf(prizeText)] : '');
								r.push('</td>');
							r.push('</tr>');
						}

						r.push('<tr>');
							r.push('<td class="tablebody" colspan="5">');
								r.push('&nbsp;');
							r.push('</td>');
						r.push('</tr>');

						var winNum = 0;
						var yourNum = 0;
						var winSymb = '';
						var yourSymb = '';

						for (gamePart=1; gamePart<=2; gamePart++)
						{
							winNum = gameData["game2"+gamePart].winNum;
							winSymb = 'symb' + winNum;

							for (turnPart=0; turnPart<3; turnPart++)
							{
								yourNum = gameData["game2"+gamePart].turns[turnPart].yourNum;
								yourSymb = 'symb' + yourNum;
								showWin = (winNum == yourNum);
								prizeText = gameData["game2"+gamePart].turns[turnPart].prize;

								r.push('<tr>');
									r.push('<td class="tablebody">');
										r.push((turnPart==0) ? getTranslationByName("gameNum", translations) + ' 2 ' + getTranslationByName("gameRow", translations) + ' ' + (gamePart+2) + ':' : '');
									r.push('</td>');
									r.push('<td class="tablebody">');
										r.push((turnPart==0) ? getTranslationByName("winSymb", translations) + ': ' + getTranslationByName(winSymb, translations) : '');
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
										r.push(getTranslationByName("playSymb", translations) + ' ' + (turnPart + 1) + ': ' + getTranslationByName(yourSymb, translations) +
											   ((showWin) ? ' ' + getTranslationByName("youMatched", translations) : ''));
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
										r.push(getTranslationByName("gamePrize", translations) + ': ' + prizeValues[prizeNames.indexOf(prizeText)]);
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
										r.push((showWin) ? getTranslationByName("win", translations) + ' ' + prizeValues[prizeNames.indexOf(prizeText)] : '');
									r.push('</td>');
								r.push('</tr>');
							}
						}

						r.push('<tr>');
							r.push('<td class="tablebody" colspan="5">');
								r.push('&nbsp;');
							r.push('</td>');
						r.push('</tr>');

						var tokenArray = gameData.bonus.tokens.split("");
						var tokenSum = tokenArray.reduce(function(a,b){return parseInt(a)+parseInt(b)},0);
						showWin = (tokenSum == 3);
						var showMulti = !(gameData.bonus.multi === undefined);

						r.push('<tr>');
							r.push('<td class="tablebody">');
								r.push(getTranslationByName("game3", translations) + ' ' + getTranslationByName("bonusTokens", translations) + ':');
							r.push('</td>');
							r.push('<td class="tablebody" colspan="4">');
								r.push(tokenArray);
							r.push('</td>');
						r.push('</tr>');

						r.push('<tr>');
							r.push('<td class="tablebody">');
								r.push(getTranslationByName("game3", translations) + ' ' + getTranslationByName("bonusTokens", translations) + ' ' + getTranslationByName("bonusTotal", translations) + ':');
							r.push('</td>');
							r.push('<td class="tablebody" colspan="2">');
								r.push(tokenSum);
							r.push('</td>');
							r.push('<td class="tablebody">');
								r.push(getTranslationByName("game3", translations) + ' ' + getTranslationByName("playBonusGame", translations) + ':');
							r.push('</td>');
							r.push('<td class="tablebody">');
								r.push((showWin) ? getTranslationByName("playGameYes", translations) : getTranslationByName("playGameNo", translations));
							r.push('</td>');
						r.push('</tr>');

						r.push('<tr>');
							r.push('<td class="tablebody">');
								r.push(getTranslationByName("game4", translations) + ' ' + getTranslationByName("bonusTokens", translations) + ':');
							r.push('</td>');
							r.push('<td class="tablebody" colspan="2">');
								r.push((showMulti) ? '1' : '0');
							r.push('</td>');
							r.push('<td class="tablebody">');
								r.push(getTranslationByName("game4", translations) + ' ' + getTranslationByName("playBonusGame", translations) + ':');
							r.push('</td>');
							r.push('<td class="tablebody">');
								r.push((showMulti) ? getTranslationByName("playGameYes", translations) : getTranslationByName("playGameNo", translations));
							r.push('</td>');
						r.push('</tr>');

						r.push('<tr>');
							r.push('<td class="tablebody" colspan="5">');
								r.push('&nbsp;');
							r.push('</td>');
						r.push('</tr>');

						if (showWin)
						{
							var layouts = ['0055555002200444400333001',
										   '0044440055555003330022001',
										   '0033300444400220055555001',
										   '0022003330055555004444001'];
							var layoutIndex = parseInt(gameData.game3.layout) - 1;
							var layoutPos = 0;
							var turnPart = 0;
							var turnValue = 0;
							showWin = false;
							var prizeValue = '';
							var isReal = false;

							r.push('<tr>');
								r.push('<td class="tablebody">');
									r.push(getTranslationByName("gameNum", translations) + ' 3 (' + getTranslationByName("game3", translations) + '):');
								r.push('</td>');
								r.push('<td class="tablebody" colspan="4">');
									r.push(getTranslationByName("gameLayout", translations) + ': ' + gameData.game3.layout);
								r.push('</td>');
							r.push('</tr>');

							r.push('<tr>');
								r.push('<td class="tablebody" colspan="5">');
									r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
										r.push('<tr>');
										
										for (layoutCell=1; layoutCell<=layouts[layoutIndex].length; layoutCell++)
										{
											r.push('<td class="tablebody" align="center">');
												r.push(layoutCell);
											r.push('</td>');
										}

										r.push('</tr>');
										r.push('<tr>');
										
										for (layoutCell=1; layoutCell<=layouts[layoutIndex].length; layoutCell++)
										{
											prizeText = layouts[layoutIndex][layoutCell-1];
											isReal = (prizeText != '0') ? ((parseInt(10 * getPrizeAsFloat(prizeValues[prizeNames.indexOf(prizeText)])) % 10) != 0) : false;
											prizeValue = (prizeText != '0') ? (isReal ? prizeValues[prizeNames.indexOf(prizeText)] : prizeValues[prizeNames.indexOf(prizeText)].split('.')[0]) : '-';

											r.push('<td class="tablebody" align="center">');
												r.push(prizeValue);
											r.push('</td>');
										}

										r.push('</tr>');
									r.push('</table>');
								r.push('</td>');							
							r.push('</tr>');

							r.push('<tr>');
								r.push('<td class="tablebody" colspan="5">');
									r.push('&nbsp;');
								r.push('</td>');
							r.push('</tr>');

							while (turnPart < 5 && layoutPos < 25)
							{
								turnValue = parseInt(gameData.game3.turns[turnPart]);
								layoutPos += turnValue;
								prizeText = layouts[layoutIndex][layoutPos-1];
								showWin = (layoutPos <= 25 && prizeText != '0');
								prizeValue = (prizeText != '0') ? prizeValues[prizeNames.indexOf(prizeText)] : '-';

								r.push('<tr>');
									r.push('<td class="tablebody">');
										r.push('&nbsp;');
									r.push('</td>');
									r.push('<td class="tablebody">');
										r.push(getTranslationByName("gameTurn", translations) + ' ' + (turnPart + 1) + ': ' + turnValue + ' ' + getTranslationByName("turnSteps", translations));
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');										
										r.push(getTranslationByName("gamePos", translations) + ': ' + layoutPos);
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');										
										r.push((layoutPos <= layouts[layoutIndex].length) ? getTranslationByName("gamePrize", translations) + ': ' + prizeValue : getTranslationByName("tooHigh", translations));
									r.push('</td>');
									r.push('<td class="tablebody' + ((showWin) ? ' bold' : '') + '">');
										r.push((showWin) ? getTranslationByName("win", translations) + ' ' + prizeValue : '');
									r.push('</td>');
								r.push('</tr>');

								turnPart++;
							}

							r.push('<tr>');
								r.push('<td class="tablebody" colspan="5">');
									r.push('&nbsp;');
								r.push('</td>');
							r.push('</tr>');
						}

						if (showMulti)
						{
							r.push('<tr>');
								r.push('<td class="tablebody">');
									r.push(getTranslationByName("gameNum", translations) + ' 4 (' + getTranslationByName("game4", translations) + '):');
								r.push('</td>');
								r.push('<td class="tablebody" colspan="4">');
									r.push(getTranslationByName("gameMultiplier", translations) + ': x' + gameData.multi);
								r.push('</td>');
							r.push('</tr>');
						}

						r.push('</table>');					
						
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}
					
					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getPrizeAsFloat(prize)
					{
						var prizeFloat = parseFloat(prize.replace(/[^0-9-.]/g, ''));
						return prizeFloat;
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>

				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>

				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
